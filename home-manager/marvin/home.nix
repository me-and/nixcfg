{
  config,
  lib,
  pkgs,
  personalCfg,
  ...
}:
{
  imports = [ personalCfg.homeModules.latex ];

  home.stateVersion = "25.11";

  home.file.".config/systemd/user/timers.target.wants/disk-usage-report.timer".source =
    config.home.file.".config/systemd".source + "/user/disk-usage-report.timer";

  home.packages = [
    pkgs.mypkgs.wavtoopus
    pkgs.quodlibet-without-gst-plugins # operon
  ];

  accounts.email.maildirBasePath = "${config.xdg.cacheHome}/mail";
  programs.offlineimap.enable = true;

  services.goimapnotify.enable = true;
  accounts.email.accounts.main.passwordCommand = "${pkgs.coreutils}/bin/cat ${
    config.sops.secrets."email/${config.accounts.email.accounts.main.address}/offlineimap".path
  }";
  accounts.email.accounts.main.goimapnotify.enable = true;
  accounts.email.accounts.main.goimapnotify.boxes.INBOX = {
    onNewMail = pkgs.mypkgs.writeCheckedShellScript {
      name = "sync-inbox.sh";
      runtimeInputs = with pkgs; [
        flock
        offlineimap
      ];
      text = "flock -Fx ${lib.escapeShellArg config.accounts.email.accounts.main.maildir.absPath} offlineimap -u basic -k mbnames:enabled=no -a main -f INBOX";
    };
    onNewMailPost = pkgs.mypkgs.writeCheckedShellScript {
      name = "logstuff.sh";
      runtimeInputs = [ pkgs.coreutils ];
      text = ''
        tmpdir="$(mktemp -d logstuff.XXXXX)"
        set >"$tmpdir"/set
        env >"$tmpdir"/env
        cat >"$tmpdir"/stdin
        if (( $# > 0 )); then
            printf '%q\n' "$@" >"$tmpdir"/args
        else
            touch "$tmpdir"/args
        fi
      '';
    };
  };

  services.syncthing.enable = true;
}
