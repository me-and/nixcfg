{ pkgs, ... }:
{
  home.packages = [ pkgs.nixpkgs-review ];

  systemd.user = {
    services.nixpkgs-review-cache-tidy = {
      Unit.Description = "Clean up old nixpkgs-review cache directories";
      Service.Type = "oneshot";
      Service.ExecStart = pkgs.mypkgs.writeCheckedShellScript {
        name = "nixpkgs-review-cache-tidy";
        runtimeInputs = [ pkgs.findutils ];
        text = ''
          cd "''${XDG_CACHE_HOME:-"$HOME"/.cache}"
          if [[ ! -e nixpkgs-review ]]; then
              # nixpkgs-review directory doesn't exist, so there's nothing to
              # clean up.
              exit 0
          fi

          find nixpkgs-review -depth -mindepth 1 -maxdepth 1 -mtime +90 -print -execdir rm -r {} +
        '';
      };
    };

    timers.nixpkgs-review-cache-tidy = {
      Unit.Description = "Regularly clean up old nixpkgs-review cache directories";
      Install.WantedBy = [ "timers.target" ];
      Timer = {
        OnCalendar = "monthly";
        AccuracySec = "4h";
        RandomizedDelaySec = "1h";
        RandomizedOffsetSec = "30d";
        Persistent = true;
      };
    };
  };
}
