{
  pkgs ? import <nixpkgs> {},
  lib ? pkgs.lib,
  callPackage ? pkgs.callPackage,
}: let
  inherit (lib.attrsets) filterAttrs mapAttrs;

  possiblePackageFiles = mapAttrs (name: _: ./. + "/${name}/package.nix") (builtins.readDir ./.);
  packageFiles = filterAttrs (_: value: builtins.pathExists value) possiblePackageFiles;
in
  mapAttrs (name: value: callPackage value {}) possiblePackageFiles
