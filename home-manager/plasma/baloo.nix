{
  programs.plasma.configFile = {
    baloofilerc.General = {
      folders = {
        value = "$HOME/";
        shellExpand = true;
      };
      "exclude folders" = {
        value = "$HOME/Nextcloud/,$HOME/OneDrive/";
        shellExpand = true;
      };
    };
    krunnerrc.Plugins.baloosearchEnabled = true;
  };
}
