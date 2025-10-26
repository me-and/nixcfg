{
  lib ? import <nixpkgs/lib>,
  mylib ? import ./lib.nix { inherit lib; },
  overlays ? builtins.mapAttrs (n: v: import v) (mylib.dirfiles { dir = ./overlays; }),
  pkgs ? import <nixpkgs> {
    overlays = builtins.attrValues overlays;
    config = import ./config.nix;
  },
}:
let
  # Using unionOfDisjoint to make sure I don't override anything
  # accidentally.  I am absolutely fine with overriding the broken "toil"
  # package, though, so don't worry about that!
  toilEval = builtins.tryEval pkgs.toil;
  pkgs' =
    assert !toilEval.success;
    builtins.removeAttrs pkgs [ "toil" ];

  packagesForCall = lib.attrsets.unionOfDisjoint pkgs' { inherit mylib; };
  scope = lib.packagesFromDirectoryRecursive {
    callPackage = lib.callPackageWith packagesForCall;
    newScope = extra: lib.callPackageWith (lib.attrsets.unionOfDisjoint packagesForCall extra);
    directory = ./pkgs;
  };
in
scope.packages scope
