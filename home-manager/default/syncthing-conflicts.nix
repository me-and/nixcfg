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
  options.services.syncthing.syncAlerts.enable =
    lib.mkEnableOption "reporting problems in Syncthing directories"
    // {
      default = cfg.enable;
    };

  config = lib.mkIf cfg.syncAlerts.enable {
    assertions = [
      {
        assertion = dirs != [ ];
        message = ''
          services.syncthing.syncAlerts is configured, but there are no
          directories configured under services.syncthing.settings.folders to
          check.
        '';
      }
    ];

    systemd.user = {
      services.syncthing-sync-alerts = {
        Unit.Description = "Check for synchronisation problems in Syncthing directories";
        Service = {
          Type = "oneshot";
          ExecStart = pkgs.mypkgs.writeCheckedShellScript {
            name = "report-sync-problems.sh";
            text = "exec ${lib.getExe pkgs.mypkgs.report-sync-problems} -- ${lib.escapeShellArgs dirs}";
          };
        };
      };

      timers.syncthing-sync-alerts = {
        Unit.Description = "Regular check for synchronisation problems in Syncthing directories";
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
