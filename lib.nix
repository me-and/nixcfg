{
  lib ? import <nixpkgs/lib>,
}:
let
  packagesForCall = { inherit lib; };
in
lib.packagesFromDirectoryRecursive {
  callPackage = lib.callPackageWith packagesForCall;
  newScope = extra: lib.callPackageWith (lib.attrsets.unionOfDisjoint packagesForCall extra);
  directory = ./lib;
}
