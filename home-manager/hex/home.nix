{
  config,
  pkgs,
  personalCfg,
  ...
}:
{
  imports = [
    personalCfg.homeModules.latex
    personalCfg.homeModules.mypy

    # Disabled due to:
    # https://github.com/nix-community/plasma-manager/issues/577
    # https://github.com/nix-community/plasma-manager/issues/579
    # personalCfg.homeModules.plasma
  ];
  home.stateVersion = "25.11";

  home.packages =
    with pkgs;
    [
      abcde
      android-tools # adb
      azuredatastudio
      calibre
      cardimpose
      cdrtools # For cdrecord, and in particular `cdrecord -v -minfo`
      chromium
      discord
      gnucash
      gnome-calculator # Prefer this to the KDE options
      # jellyfin-media-player # Insecure!?
      hunspell
      hunspellDicts.en-gb-ise
      inkscape
      libreoffice
      makemkv
      openscad
      poppler-utils
      prusa-slicer
      qalculate-gtk
      quodlibet-without-gst-plugins # operon
      rdfind
      scribus
      signal-desktop
      telegram-desktop
      tidal-hifi
      vlc
      zoom-us
    ]
    ++ (with pkgs.mypkgs; [
      gh-random-pr
      operons
      pd-sync-with-fileserver
      unison-nox
    ]);

  nixpkgs.config.allowUnfreePackages = [
    "azuredatastudio"
    "castlabs-electron" # For tidal-hifi
    "discord"
    "makemkv"
    "zoom"
  ];

  programs.firefox.enable = true;
  programs.keepassxc.enable = true;

  services.rclone.enable = true;
  services.rclone.mountPoints = {
    "${config.home.homeDirectory}/OneDrive" = "onedrive:";
    "${config.home.homeDirectory}/Nextcloud" = "unitelondonitc:";
  };

  accounts.email.maildirBasePath = "${config.xdg.cacheHome}/mail";

  services.syncthing = {
    enable = true;
    # TODO Swap this to using the plasmoid version.
    tray.enable = true;
  };

  programs.zapzap.enable = true;
  programs.taskwarrior.backup.enable = true;
}
