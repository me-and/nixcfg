{ config, ... }:
{
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
    maildir.path = config.accounts.email.accounts.main.address;

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
          remotepassfile = "${config.home.homeDirectory}/.${config.accounts.email.accounts.main.address}-offlineimap-password";
          folderfilter = "lambda f: not f.startswith('To/') and not f.startswith('Git/') and not f.startswith('Cygwin/') and f not in ('To', 'Git', 'Cygwin', 'Retention', '[Gmail]/Important', 'Retention/Undefined', 'Retention/0')";
          nametrans = "lambda f: f.replace('&-', '&')";
        };
      };
    };
  };

  programs.neomutt.settings.use_envelope_from = "yes";

  programs.offlineimap = {
    extraConfig = {
      general.metadata = config.accounts.email.maildirBasePath + "/offlineimap";
      mbnames = {
        enabled = true;
        filename = config.accounts.email.maildirBasePath + "/muttrc.mailboxes";
        header = "'mailboxes '";
        peritem = "'+%(accountname)s/%(foldername)s'";
        sep = "' '";
        footer = "'\\n'";
        incremental = false;
      };
    };
  };
}
