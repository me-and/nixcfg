{ lib, dirfiles }:
{
  dir ? null,
  dirs ? [ ],
}:
let
  dirs' =
    if dir == null then
      assert dirs != [ ];
      dirs
    else
      assert dirs == [ ];
      [ dir ];
in
let
  dir = throw "unexpected reference of dir";
  dirs = dirs';

  inherit (builtins)
    attrValues
    intersectAttrs
    mapAttrs
    readDir
    ;
  inherit (lib.attrsets) filterAttrs mapAttrs' nameValuePair;
  inherit (lib.lists) foldl';
  inherit (lib.modules) mkMerge;
  inherit (lib.strings) hasSuffix removeSuffix;

  dirToImports = dir: {
    imports = attrValues (dirfiles {
      inherit dir;
    });
  };
  fileToImports = file: { imports = [ file ]; };

  dirEntries = dir: readDir dir;
  directoryModulePaths = dir: filterAttrs (n: v: v == "directory") (dirEntries dir);
  fileModulePaths = dir: filterAttrs (n: v: v == "regular" && hasSuffix ".nix" n) (dirEntries dir);

  directoryModules = dir: mapAttrs (n: v: dirToImports (dir + "/${n}")) (directoryModulePaths dir);
  fileModules =
    dir:
    mapAttrs' (n: v: nameValuePair (removeSuffix ".nix" n) (fileToImports (dir + "/${n}"))) (
      fileModulePaths dir
    );

  mergeAttrsOfModules =
    x: y:
    let
      intersection = intersectAttrs x y;
      mask = mapAttrs (
        n: v:
        mkMerge [
          x."${n}"
          y."${n}"
        ]
      ) intersection;
    in
    (x // y) // mask;
in
foldl' mergeAttrsOfModules { } (
  map (dir: mergeAttrsOfModules (directoryModules dir) (fileModules dir)) dirs
)
