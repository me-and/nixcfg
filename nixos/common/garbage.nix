# Run garbage collection for root and also for each user who might have Home
# Manager profiles or similar.  Once they've all run, also run the store
# optimisation.
{config, ...}: let
  normalUsers = builtins.filter (user: user.isNormalUser) (builtins.attrValues config.users.users);
  normalUserNames = map (user: user.name) normalUsers;
  usersToGarbageCollect = ["root"] ++ normalUserNames;
in {
  # Separate units for each user that might have profiles to clean up, as they
  # all need to be run separately as each user per
  # https://github.com/NixOS/nix/issues/8508#issuecomment-1632805842
  systemd.services."nix-gc@" = {
    description = "Nix garbage collection";
    onSuccess = ["nix-optimise.service"];
    before = ["nix-optimise.service"];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${config.nix.package.out}/bin/nix-collect-garbage --delete-older-than 7d";
      User = "%I";
      Nice = 10;
    };
  };

  # The timers should all fire at once; we can't avoid running nix-gc multiple
  # times, at least without finding a better way to tidy up all old profiles
  # for all users, but this will at least mean there's only one following run
  # of nix-optimise.
  systemd.timers."nix-gc@" = {
    description = "Weekly Nix garbage collection";
    timerConfig = {
      # Randomly picked.
      OnCalendar = "Wed 05:39:15";
      AccuracySec = "24h";
      Persistent = true;
    };
  };

  # We're using systemd templates for the nix-gc units, so it's not possible to
  # get Nix to enable them for the right users.  Instead, enable them by adding
  # Wants dependencies from timers.target.
  systemd.targets.timers.wants = map (n: "nix-gc@${n}.timer") usersToGarbageCollect;
}
