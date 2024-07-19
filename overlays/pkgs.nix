# This file based heavily on <nixpkgs/pkgs/top-level/by-name-overlay.nix>
let
  lib = import <nixpkgs/lib>;

  inherit (lib.attrsets) filterAttrs mapAttrs;

  pkgDir = ../pkgs;
  possiblePackageFiles = mapAttrs (name: _: pkgDir + "/${name}/package.nix") (builtins.readDir pkgDir);
  packageFiles = filterAttrs (_: value: builtins.pathExists value) possiblePackageFiles;
in
  final: prev: mapAttrs (name: value: final.callPackage value {}) packageFiles
