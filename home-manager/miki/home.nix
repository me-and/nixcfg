{
  config,
  pkgs,
  personalCfg,
  ...
}:
{
  imports = [
    personalCfg.homeModules.discord
    personalCfg.homeModules.fonts
    personalCfg.homeModules.plasma
  ];

  home.stateVersion = "25.11";

  home.packages = with pkgs; [
    azuredatastudio
    gnome-calculator # Prefer this to the KDE options
    gnucash
    hunspell
    hunspellDicts.en-gb-ise
    inkscape
    jellyfin-desktop
    libreoffice
    openscad
    poppler-utils
    rdfind
    signal-desktop
    telegram-desktop
    tidal-hifi
    zoom-us
  ];

  nixpkgs.config.allowUnfreePackages = [
    "azuredatastudio"
    "castlabs-electron" # For tidal-hifi
    "zoom"
  ];

  programs.element-desktop.enable = true;
  programs.firefox.enable = true;
  programs.keepassxc.enable = true;
  programs.taskwarrior.backup.enable = true;
  programs.zapzap.enable = true;

  accounts.email.maildirBasePath = "${config.xdg.cacheHome}/mail";

  services.rclone = {
    enable = true;
    mountPoints = {
      "${config.home.homeDirectory}/OneDrive" = "onedrive:";
      "${config.home.homeDirectory}/Nextcloud" = "unitelondonitc:";
    };
  };

  services.syncthing = {
    enable = true;
    # TODO Swap this to using the plasmoid version.
    tray.enable = true;
  };
}
