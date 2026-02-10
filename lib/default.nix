{
  lib ? import <nixpkgs/lib>,

  # utils provides some things that are perfectly sensible library functions
  # that only depend on lib, and some things that are much more complex.  I
  # want access to the simple and sensible bits.
  utils ? import <nixpkgs/nixos/lib/utils.nix> {
    inherit lib;
    config = throw "unexpected config access";
    pkgs = throw "unexpected pkgs access";
  },
}:
let
  packagesForCall = { inherit lib utils; };
  scope = lib.packagesFromDirectoryRecursive {
    callPackage = lib.callPackageWith packagesForCall;
    newScope = extra: lib.callPackageWith (lib.attrsets.unionOfDisjoint packagesForCall extra);
    directory = ./.;
  };
in
builtins.removeAttrs (scope.packages scope) [ "default" ]
