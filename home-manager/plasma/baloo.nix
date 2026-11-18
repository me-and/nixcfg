{
  programs.plasma.configFile = {
    baloofilerc.General = {
      folders = {
        value = "$HOME/";
        shellExpand = true;
      };
      "exclude folders" = {
        value = "$HOME/Nextcloud/,$HOME/OneDrive/,$HOME/vcs/,$HOME/Games/";
        shellExpand = true;
      };
    };
    krunnerrc.Plugins.baloosearchEnabled = true;
  };
}
