{ pkgs, ... }:
{
  allowUnfreePredicate =
    pkg:
    builtins.elem (pkgs.lib.getName pkg) [
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

  # Work around for https://github.com/NixOS/nixpkgs/issues/456994
  # allowlistedLicenses = [ pkgs.mylib.licenses.licensedToMe ];
  allowlistedLicenses = [ (import ./lib/licenses.nix { }).licensedToMe ];
}
