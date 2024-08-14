let
  # This might be easier using functions from pkgs.lib, but there's a bootstrap
  # problem there, so the function below works out the list of overlay file
  # paths while only using Nix builtin functions.
  overlayDir = ../overlays;
  overlayFileNames = builtins.attrNames (builtins.readDir overlayDir);
  overlayFiles = map (v: overlayDir + ("/" + v)) overlayFileNames;
in
  {
    pkgsPath ? <nixpkgs>,
    pkgs ? import pkgsPath {overlays = map import overlayFiles;},
    lib ? pkgs.lib,
    callPackage ? pkgs.callPackage,
  }: let
    inherit (lib.attrsets) filterAttrs mapAttrs;

    possiblePackageFiles = mapAttrs (name: _: ./. + "/${name}/package.nix") (builtins.readDir ./.);
    packageFiles = filterAttrs (_: value: builtins.pathExists value) possiblePackageFiles;
  in
    mapAttrs (name: value: callPackage value {}) packageFiles
