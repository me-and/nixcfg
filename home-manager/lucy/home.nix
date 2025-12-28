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
    "report-onedrive-conflicts"
    "taskwarrior-inbox"
    "taskwarrior-monthly"
    "taskwarrior-project-check"
  ];
  systemdPathSymlinks = map systemdWantsPath [
    "taskwarrior-dinwoodie.org-emails"
    "sign-petitions"
  ];

  systemdSymlinks = lib.mergeAttrsList (
    systemdServiceSymlinks ++ systemdTimerSymlinks ++ systemdPathSymlinks
  );
in
{
  imports = [ personalCfg.homeModules.latex ];
  home.stateVersion = "25.11";

  # Enable all the systemd units I want running.  These are mostly coming from
  # the user-systemd-config GitHub repo, which isn't integrated into Nix and
  # therefore everything needs to be done manually.
  home.file = lib.mkIf config.systemd.user.enable systemdSymlinks;

  home.packages = [
    pkgs.mypkgs.wavtoopus
    pkgs.quodlibet-without-gst-plugins # operon
  ];

  systemd.user.services = {
    taskwarrior-create-recurring-tasks = {
      Unit = {
        Description = "Create recurring Taskwarrior tasks";
        Wants = [ "taskwarrior-sync.service" ];
        After = [ "taskwarrior-sync.service" ];
        OnSuccess = [ "taskwarrior-sync.service" ];
      };
      Service.Type = "oneshot";
      Service.ExecStart = "${config.programs.taskwarrior.package}/bin/task rc.recurrence=true ids";
    };
    taskwarrior-check-active-tasks = {
      Unit = {
        Description = "Check for Taskwarrior tasks that have been active too long";
        Wants = [ "taskwarrior-sync.service" ];
        After = [ "taskwarrior-sync.service" ];
        OnSuccess = [ "taskwarrior-sync.service" ];
      };
      Service.Type = "oneshot";
      Service.ExecStart = pkgs.mypkgs.writeCheckedShellScript {
        name = "flag-stale-active-tasks.sh";
        runtimeInputs = [ config.programs.taskwarrior.package ];
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
      Unit.Description = "Regularly create recurring Taskwarrior tasks";
      Install.WantedBy = [ "timers.target" ];
      Timer = {
        OnActiveSec = "0s";
        OnUnitInactiveSec = "12h";
        RandomizedDelaySec = "12h";
        AccuracySec = "12h";
      };
    };
    taskwarrior-check-active-tasks = {
      Unit.Description = "Regularly check for tasks that have been active too long";
      Install.WantedBy = [ "timers.target" ];
      Timer = {
        OnActiveSec = "0s";
        OnUnitInactiveSec = "24h";
        RandomizedDelaySec = "24h";
        AccuracySec = "24h";
      };
    };
    "offlineimap-full@main" = {
      Unit.Description = "Daily sync of all labels for account main";
      Install.WantedBy = [ "timers.target" ];
      Timer.OnCalendar = "06:00";
      Timer.RandomizedDelaySec = "1h";
      Timer.AccuracySec = "1h";
    };
  };

  services.rclone.enable = true;
  services.rclone.mountPoints = {
    "${config.home.homeDirectory}/OneDrive" = "onedrive:";
  };

  accounts.email.maildirBasePath = "${config.xdg.cacheHome}/mail";
  programs.offlineimap.enable = true;
  programs.neomutt.enable = true;

  services.syncthing.enable = true;

  programs.taskwarrior.onedriveBackup = true;
}
