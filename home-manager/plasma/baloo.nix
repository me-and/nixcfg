{
  programs.plasma.configFile = {
    baloofilerc.General = {
      "exclude folders[$e]" = "$HOME/Nextcloud/,$HOME/OneDrive/";
      "folders[$e]" = "$HOME/";
    };
    krunnerrc.Plugins.baloosearchEnabled = true;
  };
}
