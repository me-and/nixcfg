{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.syncthing;

  dirs = lib.map (f: f.path) (lib.filter (f: f.enable) (lib.attrValues cfg.settings.folders));
in
{
  options.services.syncthing.conflictAlerts.enable =
    lib.mkEnableOption "reporting conflicts in Syncthing directories"
    // {
      default = cfg.enable;
    };

  config = lib.mkIf cfg.conflictAlerts.enable {
    assertions = [
      {
        assertion = dirs != [ ];
        message = ''
          services.syncthing.conflictAlerts is configured, but there are no
          directories configured under services.syncthing.settings.folders to
          check.
        '';
      }
    ];

    systemd.user = {
      services.syncthing-conflicts = {
        Unit.Description = "Check for file conflicts in Syncthing directories";
        Service = {
          Type = "oneshot";
          ExecStart = pkgs.mypkgs.writeCheckedShellScript {
            name = "report-conflicts.sh";
            text = "exec ${lib.getExe pkgs.mypkgs.report-conflicts} -- ${lib.escapeShellArgs dirs}";
          };
        };
      };

      timers.syncthing-conflicts = {
        Unit.Description = "Regular check for file conflicts in Syncthing directories";
        Install.WantedBy = [ "timers.target" ];
        Timer = {
          OnCalendar = "daily";
          AccuracySec = "1h";
          RandomizedDelaySec = "1h";
          RandomizedOffsetSec = "1d";
          Persistent = true;
        };
      };
    };
  };
}
