{ lib }:
{
  dir,
  filename,
  excludes ? [ ],
}:
let
  inherit (builtins) pathExists readDir;
  inherit (lib.attrsets) filterAttrs mapAttrs;

  possibleFiles = mapAttrs (n: v: dir + "/${n}/${filename}") (readDir dir);
in
filterAttrs (n: v: pathExists v && !builtins.elem n excludes) possibleFiles
