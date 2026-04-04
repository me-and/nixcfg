{
  pkgs,
  lib ? pkgs.lib,
  mylib ? import ./lib { inherit lib; },
  ...
}:
{
  allowlistedLicenses = [ mylib.licenses.licensedToMe ];
}
