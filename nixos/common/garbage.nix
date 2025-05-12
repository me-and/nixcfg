{
  nix.nhgc = {
    enable = true;
    options = ["--penalize-substitutable"];
    # Randomly chosen.
    schedule = "Tue 06:46:03";
  };
  systemd.timers.nix-nhgc.timerConfig = {
    Persistent = true;
    AccuracySec = "24h";
    RandomizedDelaySec = "1h";
  };
  nix.settings.auto-optimise-store = true;
}
