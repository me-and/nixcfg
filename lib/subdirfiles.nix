{lib}: {
  dir,
  filename,
}: let
  inherit (builtins) pathExists readDir;
  inherit (lib.attrsets) filterAttrs mapAttrs;

  possibleFiles = mapAttrs (name: _: dir + "/${name}/${filename}") (readDir dir);
in
  filterAttrs (_: value: pathExists value) possibleFiles
