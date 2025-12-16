{
  lib ? import <nixpkgs/lib>,
  mylib ? import ../lib { inherit lib; },
  overlays ? builtins.attrValues (
    builtins.mapAttrs (n: v: import v) (mylib.dirfiles { dir = ../overlays; })
  ),
  pkgs ? import <nixpkgs> {
    inherit overlays;
    config = import ../config.nix;
  },
  inputs ? { },
}:
let
  # Using unionOfDisjoint to make sure I don't override anything
  # accidentally.
  packagesForCall = lib.attrsets.unionOfDisjoint pkgs { inherit inputs; };
  scope = lib.packagesFromDirectoryRecursive {
    callPackage = lib.callPackageWith packagesForCall;
    newScope = extra: lib.callPackageWith (packagesForCall // extra);
    directory = ./.;
  };
in
builtins.removeAttrs (scope.packages scope) [ "default" ]
