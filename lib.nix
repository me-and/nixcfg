{lib ? (import <nixpkgs> {}).lib}: let
  packagesForCall = {inherit lib;};
in
  lib.packagesFromDirectoryRecursive {
    callPackage = lib.callPackageWith packagesForCall;
    newScope = extra: lib.callPackageWith (packagesForCall // extra);
    directory = ./lib;
  }
