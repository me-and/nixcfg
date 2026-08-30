{ lib, pkgs, ... }:
{
  home.packages = [ pkgs.npb ];

  systemd.user = {
    services.npb-tidy = {
      Unit.Description = "Clean up old npb cache content";
      Service.Type = "oneshot";
      Service.ExecStart = "${lib.getExe pkgs.npb} --clean 90d";
    };

    timers.npb-tidy = {
      Unit.Description = "Regularly clean up old npb cache content";
      Install.WantedBy = [ "timers.target" ];
      Timer = {
        OnCalendar = "monthly";
        AccuracySec = "4h";
        RandomizedDelaySec = "1h";
        RandomizedOffsetSec = "30d";
        Persistent = true;
      };
    };
  };
}
