{
  config,
  lib,
  mylib,
  ...
}:
let
  cfg = config.programs.taskwarrior;

  taskwarriorRcToBool = lib.flip builtins.elem [
    "1"
    "on"
    "yes"
    "y"
    "true"
    true
    1
  ];
in
{
  options.programs.taskwarrior.recurrence = {
    enableAlways = lib.mkEnableOption "" // {
      description = ''
        Whether to enable creating recurring Taskwarrior tasks as part of regular Taskwarrior activity.

        This sets the `recurrence` taskrc option.
      '';
    };
    enableWithGc = lib.mkEnableOption "" // {
      description = ''
        Whether to enable creating recurring Taskwarrior tasks at the same time
        as Taskwarrior garbage collection.

        This is particularly useful with Taskwarrior v3, where creating
        recurring tasks doesn't work if it isn't run at the same time as
        garbage collection.
      '';
    };
    systemdSchedule.enable = lib.mkEnableOption "creating recurring Taskwarrior tasks using a Systemd timer";
    systemdSchedule.timerConfig = lib.mkOption {
      description = ''
        Configuration to set on the systemd timer unit used for triggering
        creating recurring Taskwarrior tasks.
      '';
      default = {
        OnActiveSec = "0s";
        OnUnitInactiveSec = "8h";
        RandomizedDelaySec = "8h";
        AccuracySec = "8h";
      };
    };
  };

  config = {
    warnings =
      lib.optional (cfg.recurrence.enableAlways && cfg.recurrence.systemdSchedule.enable) ''
        Both programs.taskwarrior.recurrence.enableAlways and
        programs.taskwarrior.recurrence.systemdSchedule.enable are set.  You
        normally only want one or the other.
      ''
      ++
        lib.optional
          (
            (cfg.recurrence.enableAlways || cfg.recurrence.systemdSchedule.enable)
            && lib.versionAtLeast cfg.package.version "3"
            && !taskwarriorRcToBool cfg.config.gc
          )
          ''
            One of programs.taskwarrior.recurrence.enableAlways or
            programs.taskwarrior.recurrence.systemdSchedule.enable is set, but
            you are using Taskwarrior v3 and don't have garbage collection
            enabled by default.  Consider setting both these options to
            `false`, and programs.taskwarrior.recurrence.enableWithGc to
            `true`: Taskwarrior v3 will only create recurring tasks at the same
            time as performing garbage collection.
          ''
      ++ lib.optional (cfg.recurrence.enableWithGc && cfg.recurrence.systemdSchedule.enable) ''
        Both programs.taskwarrior.recurrence.enableWithGc and
        programs.taskwarrior.recurrence.systemdSchedule.enable are set.  You
        normally only want one or the other.
      ''

    ;

    programs.taskwarrior.config.recurrence = cfg.recurrence.enableAlways;

    systemd.user = lib.mkIf cfg.recurrence.systemdSchedule.enable {

      services = {
        taskwarrior-create-recurring-tasks = {
          Unit = {
            Description = "Create recurring Taskwarrior tasks";
            Wants = [ "taskwarrior-sync.service" ];
            After = [ "taskwarrior-sync.service" ];
            OnSuccess = [ "taskwarrior-sync.service" ];
          };
          Service.Type = "oneshot";
          Service.ExecStart = mylib.escapeSystemdExecArgs [
            (lib.getExe cfg.package)
            "rc.recurrence=1"
            "ids"
          ];
        };
      };

      timers = {
        taskwarrior-create-recurring-tasks = {
          Unit.Description = "Regularly create recurring Taskwarrior tasks";
          Install.WantedBy = [ "timers.target" ];
          Timer = cfg.recurrence.systemdSchedule.timerConfig;
        };
      };
    };
  };
}
