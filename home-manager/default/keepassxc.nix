{
  programs.keepassxc = {
    autostart = true;

    settings = {
      General.ConfigVersion = 2;
      Browser = {
        Enabled = true;
        MatchUrlScheme = false;
        SearchInAllDatabases = true;
      };
      GUI = {
        MinimizeOnClose = true;
        MinimizeOnStartup = true;
        ShowTrayIcon = true;
        TrayIconAppearance = "colorful";
      };
      Security.IconDownloadFallback = true;
    };
  };
}
