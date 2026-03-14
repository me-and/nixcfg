{
  config,
  lib,
  pkgs,
  mylib,
  ...
}:
let
  fullFsList = builtins.attrValues config.fileSystems;
  btrfsFsList = builtins.filter (fs: fs.fsType == "btrfs") fullFsList;

  isDeviceInList = list: device: builtins.any (fs: fs.device == device) list;
  uniqueDeviceFsList = builtins.foldl' (acc: fs: acc ++ lib.optional (!isDeviceInList acc fs) fs) [ ] btrfsFsList;
in
{
  environment.systemPackages = lib.optional (btrfsFsList != [ ]) pkgs.btdu;

  # Based heavily on the NixOS btrfs module, except this will resume a
  # cancelled scrub, e.g. if the system was turned off before the job
  # completed.
  systemd = {
    timers =
    let
      scrubTimers =
        fs:
        let fs' = mylib.escapeSystemdPath fs.mountPoint;
        in
        {
          "btrfs-scrub@${fs'}" = {
            description = "Regular btrfs scrub of %f";
            wantedBy = [ "timers.target" ];
            timerConfig = {
              OnCalendar = "weekly";
              AccuracySec = "1d";
              RandomizedOffsetSec = "7d";
              Persistent = true;
            };
          };
        };
    in
    mylib.unionOfDisjointAttrsList (lib.map scrubTimers uniqueDeviceFsList);

    services =
      let
        scrubServices =
          fs:
          let fs' = mylib.escapeSystemdPath fs.mountPoint;
          in
          {
            "btrfs-scrub-resume@${fs'}" = {
              description = "Finish any incomplete btrfs scrub on %f";
              wantedBy = [ "multi-user.target" ];
              documentation = [ "man:btrfs-scrub(8)" ];
              conflicts = [
                "shutdown.target"
                "sleep.target"
              ];
              before = [
                "shutdown.target"
                "sleep.target"
              ];

              # TODO main unit to be started by the timer, plus oneshot unit pulled in by sleep.target with RemainAfterExit, StopWhenUnneeded, WantedBy=sleep.target, OnSuccess=btrfs-scrub-resume@, as documented for sleep.target
  };
}
