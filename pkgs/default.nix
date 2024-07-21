let
  overlayDir = ../overlays;
  overlayFiles = let
    lib = import <nixpkgs/lib>;
  in
    lib.attrsets.mapAttrsToList
    (name: value: lib.path.append overlayDir name)
    (builtins.readDir overlayDir);
in
  {
    pkgs ? import <nixpkgs> {overlays = map import overlayFiles;},
    lib ? pkgs.lib,
    callPackage ? pkgs.callPackage,
  }: let
    inherit (lib.attrsets) filterAttrs mapAttrs;

    possiblePackageFiles = mapAttrs (name: _: ./. + "/${name}/package.nix") (builtins.readDir ./.);
    packageFiles = filterAttrs (_: value: builtins.pathExists value) possiblePackageFiles;
  in
    mapAttrs (name: value: callPackage value {}) packageFiles
