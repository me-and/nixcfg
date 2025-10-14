{ lib, dirfiles }:
{
  dir,
}:
let
  inherit (builtins) readDir;
  inherit (lib.attrsets) mapAttrs' nameValuePair;
  inherit (lib.strings) removeSuffix;

  dirToImports = dir: {
    imports = builtins.attrValues (dirfiles {
      inherit dir;
    });
  };
  fileToImports = file: { imports = [ file ]; };
in
mapAttrs' (
  n: v:
  nameValuePair (removeSuffix ".nix" n) (
    (
      if v == "regular" then
        fileToImports
      else if v == "directory" then
        dirToImports
      else
        throw "Unexpected directory entry type ${v}"
    )
      (dir + "/${n}")
  )
) (readDir dir)
