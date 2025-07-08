{config, ...}: {
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

  accounts.email.accounts.main.offlineimap = {
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
}
