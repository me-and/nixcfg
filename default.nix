let
  overlayDir = ./overlays;
  overlayFileNames = builtins.attrNames (builtins.readDir overlayDir);
  overlayFiles = map (v: overlayDir + ("/" + v)) overlayFileNames;
in
  {
    pkgs ? import <nixpkgs> {overlays = map import overlayFiles;},
    lib ? pkgs.lib,
  }:
    lib.packagesFromDirectoryRecursive {
      inherit (pkgs) callPackage newScope;
      directory = ./pkgs;
    }
