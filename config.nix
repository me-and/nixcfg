{
  pkgs,
  lib ? pkgs.lib,
  mylib ? import ./lib { inherit lib; },
  ...
}:
{
  allowlistedLicenses = [ mylib.licenses.licensedToMe ];

  # Needed to allow tests to run while I'm overriding MakeMKV.
  allowUnfreePackages = [ "makemkv" ];
}
