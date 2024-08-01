# I'm honestly baffled that this isn't default upstream systemd behaviour: if a
# unit is ordering itself after time-sync.target, and systemd-timesyncd.service
# is in use, surely this unit should be present too, just based on the
# documentation in the systemd.special(7) man page.
{pkgs, ...}: {
  # TODO Work out why I can't get boot.initrd.systemd.additionalUpstreamUnits
  # to pull this in; the config below is basically copied straight out of the
  # systemd upstream file.
  systemd.services.systemd-time-wait-sync = {
    description = "Wait Until Kernel Time Synchronized";
    documentation = ["man:systemd-time-wait-sync.service(8)"];
    unitConfig = {
      ConditionCapability = ["CAP_SYS_TIME"];
      ConditionVirtualization = ["!container"];
      DefaultDependencies = false;
    };
    before = ["time-sync.target" "shutdown.target"];
    wants = ["time-sync.target"];
    conflicts = ["shutdown.target"];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.systemd}/lib/systemd/systemd-time-wait-sync";
      TimeoutStartSec = "infinity";
      RemainAfterExit = true;
    };
    wantedBy = ["sysinit.target"];
  };
}
