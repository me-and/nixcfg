{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.accounts.email;

  accountSubmodule =
    { config, lib, ... }:
    {
      options.passwordFile = lib.mkOption {
        description = "Path to a file that contains the password for this account.";
        type = with lib.types; nullOr str;
        example = lib.literal "config.sops.secrets.emailPasswd.path";
        default = null;
      };

      config = lib.mkIf (config.passwordFile != null) {
        # Configuration using the passwordFile option.
        passwordCommand = lib.mkDefault [
          "${pkgs.coreutils}/bin/cat"
          config.passwordFile
        ];
        offlineimap.extraConfig.remote.remotepassfile = lib.mkDefault config.passwordFile;

        # Configuration that's just defaults I'd like for my accounts.
        realName = lib.mkDefault "Adam Dinwoodie";
        maildir.path = lib.mkDefault config.address;
        offlineimap.enable = lib.mkDefault true;
      };
    };
in
{
  options.accounts.email = {
    primaryAccount = lib.mkOption {
      description = "The primary email account";
      readOnly = true;
    };

    accounts = lib.mkOption {
      type = with lib.types; attrsOf (submodule accountSubmodule);
    };
  };

  config = {
    accounts.email.primaryAccount = lib.lists.findFirst (a: a.enable && a.primary) null (
      builtins.attrValues cfg.accounts
    );

    # Configure accounts.email.accounts.*.address in private config flake.
    accounts.email.accounts = {
      main = {
        primary = true;
        realName = "Adam Dinwoodie";

        flavor = "gmail.com";

        # Folders use the offlineimap format, since that's how I'm syncing them.
        folders = {
          inbox = "INBOX";
          drafts = "[Gmail].Drafts";
          sent = "[Gmail].Sent Mail";
        };
        maildir.path = cfg.accounts.main.address;

        neomutt = {
          enable = true;
          extraConfig = ''
            set reverse_name = yes
            unset reverse_realname
            alternates '[@\.]dinwoodie\.org$' '^adam@profounddecisions\.co\.uk$' '^(adamdinwoodie|gamma3000|knightley\.nightly|sorrowfulsnail)@(gmail|googlemail)\.com$' '^adam@tastycake\.net$' '^adam\.dinwoodie@worc\.oxon\.org$'

            # Don't move deleted messages to the trash; Gmail will interpret that to
            # mean they should be deleted permanently after 30 days, where I want
            # them to stay in my All Mail directory.
            unset trash
          '';
        };

        offlineimap = {
          extraConfig = {
            account = {
              synclabels = true;
              labelsheader = "X-Labels";
            };
            local = {
              nametrans = "lambda f: f.replace('&', '&-')";
              utime_from_header = true;
            };
            remote = {
              maxconnections = 4;
              folderfilter = "lambda f: not f.startswith('To/') and not f.startswith('Git/') and not f.startswith('Cygwin/') and f not in ('To', 'Git', 'Cygwin', 'Retention', '[Gmail]/Important', 'Retention/Undefined', 'Retention/0')";
              nametrans = "lambda f: f.replace('&-', '&')";
            };
          };
        };
      };

      pd = { };

      taskwarrior = {
        enable = lib.mkDefault false;
      };
    };

    programs.neomutt.settings.use_envelope_from = "yes";

    programs.offlineimap = {
      extraConfig = {
        general.metadata = cfg.maildirBasePath + "/offlineimap";
        mbnames = {
          enabled = true;
          filename = cfg.maildirBasePath + "/muttrc.mailboxes";
          header = "'mailboxes '";
          peritem = "'+%(accountname)s/%(foldername)s'";
          sep = "' '";
          footer = "'\\n'";
          incremental = false;
        };
      };
    };
  };
}
