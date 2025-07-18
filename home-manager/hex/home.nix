{
  config,
  lib,
  pkgs,
  ...
}: let
  systemdWantsAlias = baseUnit: instanceUnit: from: {
    ".config/systemd/user/${from}.wants/${instanceUnit}".source = config.home.file.".config/systemd".source + "/user/${baseUnit}";
  };
  systemdWants = unit: systemdWantsAlias unit unit;
  systemdWantsInstance = unit: instance: let
    instanceUnit = builtins.replaceStrings ["@."] ["@${instance}."] unit;
  in
    systemdWantsAlias unit instanceUnit;

  homeshickReportWants = dir: systemdWantsInstance "homeshick-pull@.service" dir "homeshick-report.service";

  systemdWantsService = name: systemdWants "${name}.service" "default.target";
  systemdWantsTimer = name: systemdWants "${name}.timer" "timers.target";
  systemdWantsPath = name: systemdWants "${name}.path" "paths.target";

  systemdServiceSymlinks = map systemdWantsService [];
  systemdHomeshickReportSymlinks = map homeshickReportWants [
    "homeshick"
  ];
  systemdTimerSymlinks = map systemdWantsTimer [
    "disk-usage-report"
  ];
  systemdPathSymlinks = [];

  systemdSymlinks = lib.mergeAttrsList (
    systemdServiceSymlinks
    ++ systemdHomeshickReportSymlinks
    ++ systemdTimerSymlinks
    ++ systemdPathSymlinks
  );
in {
  imports = [./fonts.nix];

  home.stateVersion = "24.11";

  home.packages = with pkgs; [
    abcde
    android-tools # adb
    azuredatastudio
    cardimpose
    cdrtools # For cdrecord, and in particular `cdrecord -v -minfo`
    discord
    freecad
    gh-random-pr
    gnucash
    gnome-calculator # Prefer this to the KDE options
    jellyfin-media-player
    hunspell
    hunspellDicts.en-gb-ise
    inkscape
    libreoffice
    makemkv
    unison-nox
    openscad
    pd-sync-with-fileserver
    poppler_utils
    prusa-slicer
    qalculate-gtk
    scribus
    signal-desktop
    telegram-desktop
    vlc
    whatsapp-for-linux
    zoom-us
  ];

  programs.firefox.enable = true;

  # Enable all the systemd units I want running.  These are mostly coming from
  # the user-systemd-config GitHub repo, which isn't integrated into Nix and
  # therefore everything needs to be done manually.
  home.file = lib.mkIf config.systemd.user.enable systemdSymlinks;

  services.rclone.enable = true;
  services.rclone.mountPoints = {
    "${config.home.homeDirectory}/OneDrive" = "onedrive:";
    "${config.home.homeDirectory}/Nextcloud" = "unitelondonitc:";
  };

  # Configure accounts.email.accounts.*.address in private config flake.
  accounts.email.accounts.main = {
    flavor = "gmail.com";
    folders = {
      inbox = "INBOX";
      drafts = "[Gmail]/Drafts";
      sent = "[Gmail]/Sent Mail";
      trash = "[Gmail]/Bin";
    };
    # TODO configure this?
    #maildir.path = config.accounts.email.accounts.main.address;
    # TODO configure this, with all the attentant options
    #neomutt.enable = true;
    # TODO configure this, with all the attendant options
    #offlineimap.enable = true;
    primary = true;
    realName = "Adam Dinwoodie";
  };
  accounts.email.maildirBasePath = "${config.xdg.cacheHome}/mail";
  accounts.email.forwardLocal.enable = true;

  programs.keepassxc.enable = true;

  pd.enable = true;

  programs.mypy.enable = true;

  services.syncthing = {
    enable = true;
    tray.enable = true;
  };
}
