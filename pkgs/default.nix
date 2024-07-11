# To allow this file to be used in ../overlays/pkgs.nix, the names of the
# attributes it returns must be constant for any (reasonable) set of passed in
# arguments.
{
  pkgs ? import <nixpkgs> {},
  lib ? pkgs.lib,
  callPackage ? pkgs.callPackage,
}: let
  dirContents = builtins.readDir ./.;
  possiblePackageFiles = lib.mapAttrs (n: v: lib.path.append ./. "${n}/package.nix") dirContents;
  packageFiles = lib.filterAttrs (n: v: builtins.pathExists v) possiblePackageFiles;
in
  lib.mapAttrs (n: v: callPackage v {}) packageFiles
