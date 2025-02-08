# Set up emergency.target to reboot after 15 minutes, in the hope that a system
# that has got into this state might have a chance at recovery after a reboot.
{
  systemd = {
    targets.emergency.wants = ["reboot-in-15-minutes.timer"];
    timers.reboot-in-15-minutes = {
      unitConfig.DefaultDependencies = false;
      timerConfig = {
        OnActiveSec = "15min";
        Unit = "reboot.service";
      };
      conflicts = ["shutdown.target"];
      before = ["timers.target" "shutdown.target"];
    };
    services.reboot = {
      unitConfig.DefaultDependencies = false;
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "systemctl reboot";
      };
      after = ["emergency.service"];
    };
  };
}
