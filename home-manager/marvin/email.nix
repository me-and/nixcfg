{
  config,
  lib,
  pkgs,
  ...
}:
let
  accountsCfg = config.accounts.email.accounts;
in
{
  programs.offlineimap.enable = true;

  home.packages = [ pkgs.mypkgs.mailsync ];

  services.goimapnotify.enable = true;
  accounts.email.accounts = {
    main.goimapnotify.boxes = {
      INBOX.onNewMail = "${pkgs.mypkgs.mailsync}/bin/mailsync -i";
      TaskWarrior.onNewMail = "${pkgs.mypkgs.mailsync}/bin/mailsync TaskWarrior";
    };

    pd.goimapnotify.boxes.INBOX.onNewMail = "${pkgs.mypkgs.mailsync}/bin/mailsync -e pd -i";
  };

  systemd.user = {
    services.pd-to-main = {
      Unit.Description = "Move PD emails to my main inbox";
      Service = {
        Type = "oneshot";
        ExecStart = pkgs.mypkgs.writeCheckedShellScript {
          name = "pd-to-main.sh";
          runtimeInputs = [ pkgs.coreutils ];
          text = ''
            declare -r FROM_MAILDIR=${lib.escapeShellArg accountsCfg.pd.maildir.absPath}/INBOX
            declare -r TO_MAILDIR=${lib.escapeShellArg accountsCfg.main.maildir.absPath}/INBOX

            shopt -s nullglob
            for f in "$FROM_MAILDIR"/new/* "$FROM_MAILDIR"/cur/*; do
                new="$(mktemp -p "$TO_MAILDIR"/tmp)"
                {
                    echo 'X-Labels: To/PD'
                    cat "$f"
                } >"$new"
                mv --no-clobber "$new" "$TO_MAILDIR"/new
                rm "$f"
            done

            ${pkgs.mypkgs.mailsync}/bin/mailsync -i
            ${pkgs.mypkgs.mailsync}/bin/mailsync -e pd -i
          '';
        };
      };
    };

    paths.pd-to-main = {
      Unit.Description = "Move PD emails to my main inbox";
      Path.DirectoryNotEmpty = [
        "${accountsCfg.pd.maildir.absPath}/INBOX/new"
        "${accountsCfg.pd.maildir.absPath}/INBOX/cur"
      ];
      Install.WantedBy = [ "paths.target" ];
    };
  };
}
