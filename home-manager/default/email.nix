{ config, lib, ... }:
let
  cfg = config.accounts.email;
in
{
  sops = lib.mkIf cfg.accounts.main.enable {
    secrets."email/${cfg.accounts.main.address}/offlineimap" = { };
  };

  # Configure accounts.email.accounts.*.address in private config flake.
  accounts.email.accounts.main = {
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
      enable = true;
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
          remotepassfile = config.sops.secrets."email/${cfg.accounts.main.address}/offlineimap".path;
          folderfilter = "lambda f: not f.startswith('To/') and not f.startswith('Git/') and not f.startswith('Cygwin/') and f not in ('To', 'Git', 'Cygwin', 'Retention', '[Gmail]/Important', 'Retention/Undefined', 'Retention/0')";
          nametrans = "lambda f: f.replace('&-', '&')";
        };
      };
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
}
