{lib, ...}: {
  nixpkgs.config.allowUnfreePredicate = pkg:
    builtins.elem (lib.getName pkg) [
      "albertus-fonts"
      "azuredatastudio"
      "cups-kyocera-3500-4500"
      "discord"
      "google-chrome"
      "netflix-icon"
      "netflix-via-google-chrome"
      "steam"
      "steam-original"
      "steam-unwrapped"
      "steam-run"
      "zoom"
    ];
}
