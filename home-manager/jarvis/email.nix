{
  config,
  lib,
  pkgs,
  mylib,
  ...
}:
let
  accountsCfg = config.accounts.email.accounts;

  accountSubmodule =
    {
      config,
      lib,
      name,
      ...
    }:
    {
      options.syncToPrimary = {
        enable = lib.mkEnableOption "moving emails from this account's inbox to my main email account";
        label = lib.mkOption {
          type = lib.types.strMatching "[^\n\r]+";
          description = "Label to apply to emails moved from this account";
        };
      };

      config = {
        goimapnotify = lib.mkIf config.syncToPrimary.enable {
          boxes.INBOX.onNewMail = "${pkgs.mypkgs.mailsync}/bin/mailsync -e ${lib.escapeShellArg name} -i";
        };
      };
    };

  syncingAccounts = lib.filterAttrs (n: v: v.enable && v.syncToPrimary.enable) accountsCfg;

  inherit (config.accounts.email) primaryAccount;
in
{
  options.accounts.email.accounts = lib.mkOption {
    type = with lib.types; attrsOf (submodule accountSubmodule);
  };

  config = {
    assertions = [
      {
        assertion = syncingAccounts != { } -> config.programs.offlineimap.enable;
        message = "using accounts.email.accounts.<name>.syncToPrimary requires programs.offlineimap.enable";
      }
      {
        assertion = syncingAccounts != { } -> config.services.goimapnotify.enable;
        message = "using accounts.email.accounts.<name>.syncToPrimary requires services.goimapnotify.enable";
      }
      {
        assertion = syncingAccounts != { } -> primaryAccount != null;
        message = "using accounts.email.accounts.<name>.syncToPrimary requires an email account to have primary set";
      }
      {
        assertion = primaryAccount == null || primaryAccount.syncToPrimary.enable == false;
        message = "cannot set both primary and syncToPrimary on the same email account";
      }
    ];

    programs.offlineimap.enable = true;
    programs.neomutt.enable = true;

    home.packages = [ pkgs.mypkgs.mailsync ];

    services.goimapnotify.enable = true;
    accounts.email.accounts = {
      main.goimapnotify.boxes = {
        INBOX.onNewMail = "${pkgs.mypkgs.mailsync}/bin/mailsync -i";
      };

      pd = {
        enable = true;
        syncToPrimary = {
          enable = true;
          label = "To/PD";
        };
      };

      tastycake = {
        enable = true;
        syncToPrimary = {
          enable = true;
          label = "To/Tastycake";
        };
      };
    };

    systemd.user.services = lib.concatMapAttrs (
      n: v:
      let
        escapedName = mylib.escapeSystemdString v.name;
      in
      {
        "sync-to-primary@${escapedName}" = {
          Unit.Description = "Move %i emails to my primary inbox";
          Service = {
            Type = "oneshot";
            ExecStart = pkgs.mypkgs.writeCheckedShellScript {
              name = "sync-to-main.sh";
              runtimeInputs = [ pkgs.coreutils ];
              text = ''
                declare -r FROM_MAILDIR=${lib.escapeShellArg v.maildir.absPath}/INBOX
                declare -r TO_MAILDIR=${lib.escapeShellArg primaryAccount.maildir.absPath}/INBOX

                shopt -s nullglob
                for f in "$FROM_MAILDIR"/new/* "$FROM_MAILDIR"/cur/*; do
                    new="$(mktemp -p "$TO_MAILDIR"/tmp)"
                    {
                        printf 'X-Labels: %s\n' ${lib.escapeShellArg v.syncToPrimary.label}
                        cat "$f"
                    } >"$new"
                    mv --no-clobber "$new" "$TO_MAILDIR"/new
                    rm "$f"
                done

                ${pkgs.mypkgs.mailsync}/bin/mailsync -i
                ${pkgs.mypkgs.mailsync}/bin/mailsync -e ${lib.escapeShellArg v.name} -i
              '';
            };
          };
        };
      }
    ) syncingAccounts;
    systemd.user.paths = lib.concatMapAttrs (
      n: v:
      let
        escapedName = mylib.escapeSystemdString v.name;
      in
      {
        "sync-to-primary@${escapedName}" = {
          Unit.Description = "Move %i emails to my primary inbox";
          Path.DirectoryNotEmpty = [
            "${v.maildir.absPath}/INBOX/new"
            "${v.maildir.absPath}/INBOX/cur"
          ];
          Install.WantedBy = [ "paths.target" ];
        };
      }
    ) syncingAccounts;

    systemd.user.timers."offlineimap-full@main" = {
      Timer = {
        OnActiveSec = "0s";
        OnUnitInactiveSec = "1h";
        AccuracySec = "1h";
        RandomizedDelaySec = "1h";
      };
      Install.WantedBy = [ "timers.target" ];
    };
  };
}
