{
  # Not worrying about general garbage collection here -- that's generally
  # going to be the responsibility of NixOS -- but I do want to clean up old
  # generations regularly.
  nix.gc = {
    options = "--max-freed 0 --delete-older-than 90d";
    automatic = true;
    frequency = "weekly";
    persistent = true;
    randomizedDelaySec = "1h";
  };
  systemd.user.timers.nix-gc.Timer = {
    AccuracySec = "24h";
    RandomizedOffsetSec = "1w";
  };
}
