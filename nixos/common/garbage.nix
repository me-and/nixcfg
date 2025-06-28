{
  nix.nhgc = {
    enable = true;
    options = ["--penalize-substitutable"];
    # Randomly chosen.
    schedule = "weekly";
  };
  systemd.timers.nix-nhgc.timerConfig = {
    Persistent = true;
    AccuracySec = "24h";
    RandomizedDelaySec = "1h";
    RandomizedOffsetSec = "1w";
  };
  nix.settings.auto-optimise-store = true;
}
