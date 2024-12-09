{lib, ...}: {
  nixpkgs.config.allowUnfreePredicate = pkg:
    builtins.elem (lib.getName) [
      "discord"
      "google-chrome"
      "netflix-icon"
      "netflix-via-google-chrome"
      "steam"
      "steam-original"
      "steam-run"
      "zoom"
    ];
}
