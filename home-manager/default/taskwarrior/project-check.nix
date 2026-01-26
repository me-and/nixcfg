{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.taskwarrior;
in
{
  options.programs.taskwarrior.checkProjects.enable =
    lib.mkEnableOption "regularly checking for Taskwarrior projects that no longer have any tasks";

  config = lib.mkIf cfg.checkProjects.enable {
    systemd.user = {
      services.taskwarrior-project-check = {
        Unit = {
          Description = "Check Taskwarrior project state";
          Wants = [ "taskwarrior-sync.service" ];
          After = [ "taskwarrior-sync.service" ];
          OnSuccess = [ "taskwarrior-sync.service" ];
        };
        Service.Type = "oneshot";
        Service.ExecStart =
          pkgs.runCommand "taskwarrior_projects.py" { buildInputs = [ pkgs.mypkgs.pythonWithAsmodeus ]; }
            ''
              cp ${./projects.py} "$out"
              chmod +x "$out"
              patchShebangs "$out"
            '';
      };

      timers.taskwarrior-project-check = {
        Unit.Description = "Check Taskwarrior project state daily";
        Install.WantedBy = [ "timers.target" ];
        Timer = {
          OnCalendar = "daily";
          AccuracySec = "6h";
          Persistent = true;
        };
      };
    };
  };
}
