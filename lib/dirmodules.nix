{ lib, dirfiles }:
{ dir }:
let
  inherit (builtins) attrValues mapAttrs readDir;
  inherit (lib.attrsets)
    filterAttrs
    mapAttrs'
    nameValuePair
    unionOfDisjoint
    ;
  inherit (lib.strings) hasSuffix removeSuffix;

  dirToImports = dir: {
    imports = attrValues (dirfiles {
      inherit dir;
    });
  };
  fileToImports = file: { imports = [ file ]; };

  dirEntries = readDir dir;
  directoryModulePaths = lib.filterAttrs (n: v: v == "directory") dirEntries;
  fileModulePaths = lib.filterAttrs (n: v: v == "regular" && hasSuffix ".nix" n) dirEntries;

  directoryModules = mapAttrs (n: v: dirToImports (dir + "/${n}")) directoryModulePaths;
  fileModules = mapAttrs' (
    n: v: nameValuePair (removeSuffix ".nix" n) (fileToImports (dir + "/${n}"))
  ) fileModulePaths;
in
unionOfDisjoint directoryModules fileModules
