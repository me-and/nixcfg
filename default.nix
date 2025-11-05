{
  lib ? import <nixpkgs/lib>,
  mylib ? import ./lib.nix { inherit lib; },
  overlays ? builtins.mapAttrs (n: v: import v) (mylib.dirfiles { dir = ./overlays; }),
  pkgs ? import <nixpkgs> {
    overlays = builtins.attrValues overlays;
    config = import ./config.nix;
  },
}:
let
  # Using unionOfDisjoint to make sure I don't override anything
  # accidentally.
  packagesForCall = lib.attrsets.unionOfDisjoint pkgs { inherit mylib; };
  scope = lib.packagesFromDirectoryRecursive {
    callPackage = lib.callPackageWith packagesForCall;
    newScope = extra: lib.callPackageWith (lib.attrsets.unionOfDisjoint packagesForCall extra);
    directory = ./pkgs;
  };
in
scope.packages scope
