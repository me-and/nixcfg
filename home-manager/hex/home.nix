{
  config,
  lib,
  pkgs,
  personalCfg,
  ...
}:
let
  systemdWantsAlias = baseUnit: instanceUnit: from: {
    ".config/systemd/user/${from}.wants/${instanceUnit}".source =
      config.home.file.".config/systemd".source + "/user/${baseUnit}";
  };
  systemdWants = unit: systemdWantsAlias unit unit;
  systemdWantsInstance =
    unit: instance:
    let
      instanceUnit = builtins.replaceStrings [ "@." ] [ "@${instance}." ] unit;
    in
    systemdWantsAlias unit instanceUnit;

  systemdWantsService = name: systemdWants "${name}.service" "default.target";
  systemdWantsTimer = name: systemdWants "${name}.timer" "timers.target";
  systemdWantsPath = name: systemdWants "${name}.path" "paths.target";

  systemdServiceSymlinks = map systemdWantsService [ ];
  systemdTimerSymlinks = map systemdWantsTimer [
    "disk-usage-report"
  ];
  systemdPathSymlinks = [ ];

  systemdSymlinks = lib.mergeAttrsList (
    systemdServiceSymlinks ++ systemdTimerSymlinks ++ systemdPathSymlinks
  );
in
{
  imports = [
    personalCfg.homeModules.latex
    personalCfg.homeModules.mypy
    personalCfg.homeModules.plasma
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
      discord
      freecad
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

  programs.firefox.enable = true;
  programs.keepassxc.enable = true;

  # Enable all the systemd units I want running.  These are mostly coming from
  # the user-systemd-config GitHub repo, which isn't integrated into Nix and
  # therefore everything needs to be done manually.
  home.file = lib.mkIf config.systemd.user.enable systemdSymlinks;

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
