{
  lib ? import <nixpkgs/lib>,
}:
let
  packagesForCall = { inherit lib; };
  scope = lib.packagesFromDirectoryRecursive {
    callPackage = lib.callPackageWith packagesForCall;
    newScope = extra: lib.callPackageWith (lib.attrsets.unionOfDisjoint packagesForCall extra);
    directory = ./.;
  };
in
builtins.removeAttrs (scope.packages scope) [ "default" ]
