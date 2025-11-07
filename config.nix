{
  pkgs,
  lib ? pkgs.lib,
  mylib ? import ./lib { inherit lib; },
  ...
}:
{
  allowUnfreePredicate =
    pkg:
    builtins.elem (lib.getName pkg) [
      "albertus"
      "azuredatastudio"
      "cnijfilter2"
      "cups-kyocera-3500-4500"
      "discord"
      "google-chrome"
      "makemkv"
      "netflix-icon"
      "netflix-via-google-chrome"
      "steam"
      "steam-original"
      "steam-unwrapped"
      "steam-run"
      "zoom"
    ];

  allowlistedLicenses = [ mylib.licenses.licensedToMe ];
}
