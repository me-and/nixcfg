{
  config,
  lib,
  pkgs,
  pkgsNixosUnstable,
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
  systemdTimerSymlinks =
    (
      map systemdWantsTimer [
        "disk-usage-report"
        "report-onedrive-conflicts"
        "taskwarrior-inbox"
        "taskwarrior-monthly"
        "taskwarrior-project-check"
      ]
    );
  systemdPathSymlinks = [];

  systemdSymlinks = lib.mergeAttrsList (
    systemdServiceSymlinks
    ++ systemdHomeshickReportSymlinks
    ++ systemdTimerSymlinks
    ++ systemdPathSymlinks
  );
in {
  imports = [
    ./fonts.nix
  ];

  home.stateVersion = "24.11";

  home.packages = with pkgs; [
    android-tools # adb
    azuredatastudio
    cardimpose
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
    openscad
    poppler_utils
    pkgsNixosUnstable.prusa-slicer
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

  systemd.user.services = {
    taskwarrior-create-recurring-tasks = {
      Unit.Description = "Create recurring Taskwarrior tasks";
      Service.Type = "oneshot";
      Service.ExecStart = "${config.programs.taskwarrior.package}/bin/task rc.recurrence=true ids";
    };
    taskwarrior-check-active-tasks = {
      Unit.Description = "Check for Taskwarrior tasks that have been active too long";
      Service.Type = "oneshot";
      Service.ExecStart = pkgs.writeCheckedShellScript {
        name = "flag-stale-active-tasks.sh";
        runtimeInputs = [config.programs.taskwarrior.package];
        text = ''
          task_quick_quiet () {
              task rc.color=0 rc.detection=0 rc.gc=0 rc.hooks=0 rc.recurrence=0 rc.verbose=0 "$@"
          }

          filter=(+ACTIVE -COMPLETED -DELETED modified.before:now-28d)

          declare -i stale_active_tasks
          stale_active_tasks="$(task_quick_quiet "''${filter[@]}" count)"
          if (( stale_active_tasks > 0 )); then
              task_quick_quiet rc.bulk=0 "''${filter[@]}" modify +inbox
          fi
        '';
      };
    };
  };
  systemd.user.timers = {
    taskwarrior-create-recurring-tasks = {
      Unit.Description = "Create recurring Taskwarrior tasks daily";
      Install.WantedBy = ["timers.target"];
      Timer.OnCalendar = "01:00";
      Timer.AccuracySec = "6h";
      Timer.Persistent = true;
    };
    taskwarrior-check-active-tasks = {
      Unit.Description = "Daily check for tasks that have been active too long";
      Install.WantedBy = ["timers.target"];
      Timer.OnCalendar = "01:00";
      Timer.AccuracySec = "6h";
      Timer.RandomizedDelaySec = "1h";
      Timer.Persistent = true;
    };
  };

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

  services.calendarEmails = {
    enable = true;
    calendars = [
      config.accounts.email.accounts.main.address
      "Adam Dinwoodie's Facebook Events"
    ];
  };

  pd.enable = true;

  programs.mypy.enable = true;

  programs.taskwarrior.autoSync = false;
}
