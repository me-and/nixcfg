{
  # Run the standard garbage collector regularly, not to do actual Nix store
  # garbage collection, but to clean up old profiles and stale links.
  nix.gc = {
    options = "--max-freed 0 --delete-older-than 90d";
    automatic = true;
    dates = "weekly";
    persistent = true;
    randomizedDelaySec = "1h";
  };
  systemd.timers.nix-gc.timerConfig = {
    AccuracySec = "24h";
    RandomizedOffsetSec = "1w";
  };

  # Use Nix Heuristic Garbage Collection to actually collect garbage.
  nix.nhgc = {
    enable = true;
    options = ["--penalize-substitutable"];
    schedule = "weekly";
  };
  systemd.timers.nix-nhgc.timerConfig = {
    Persistent = true;
    AccuracySec = "24h";
    RandomizedDelaySec = "1h";
    RandomizedOffsetSec = "1w";
  };

  # I expect to have lots of duplication in the store, so avoid that.
  nix.settings.auto-optimise-store = true;
}
