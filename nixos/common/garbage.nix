{
  nix.nhgc = {
    enable = true;
    optimiseAfter = true;
    options = ["--penalize-substitutable"];
    # Randomly chosen.
    schedule = "Tue 06:46:03";
  };
  systemd.timers.nix-nhgc.timerConfig = {
    Persistent = true;
    AccuracySec = "24h";
    RandomizedDelaySec = "1h";
  };
}
