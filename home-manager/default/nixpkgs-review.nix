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
          cache_dir="''${XDG_CACHE_HOME:-"$HOME"/.cache}/nixpkgs-review"
          if [[ ! -e "$cache_dir" ]]; then
              # nixpkgs-review directory doesn't exist, so there's nothing to
              # clean up.
              echo 'no nixpkgs-review cache-directory to clean' >&2
              exit 0
          fi

          find "$cache_dir" -depth -mindepth 1 -maxdepth 1 -printf '%p\t%Td %Tb %TY\n' -mtime +90 -execdir rm -rv -- {} +
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
