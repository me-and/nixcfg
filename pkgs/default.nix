{
  lib ? import <nixpkgs/lib>,
  mylib ? import ../lib { inherit lib; },
  overlays ? builtins.attrValues (
    builtins.mapAttrs (n: v: import v) (mylib.dirfiles { dir = ../overlays; })
  ),
  pkgs ? import <nixpkgs> {
    inherit overlays;
    config = import ../config.nix;
  },
  inputs ? { },
}:
let
  # Using unionOfDisjoint to make sure I don't override anything
  # accidentally.  I am absolutely fine with overriding the broken "toil"
  # package, though, so don't worry about that!
  toilEval = builtins.tryEval pkgs.toil;
  pkgs' =
    if pkgs ? toil then
      assert !toilEval.success;
      builtins.removeAttrs pkgs [ "toil" ]
    else
      builtins.warn "No need to handle toil package in default.nix" pkgs;

  packagesForCall = lib.attrsets.unionOfDisjoint pkgs' { inherit mylib inputs; };
  scope = lib.packagesFromDirectoryRecursive {
    callPackage = lib.callPackageWith packagesForCall;
    newScope = extra: lib.callPackageWith (packagesForCall // extra);
    directory = ./.;
  };
in
builtins.removeAttrs (scope.packages scope) [ "default" ]
