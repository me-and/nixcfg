let
  overlayDir = ./overlays;
  overlayFileNames = builtins.attrNames (builtins.readDir overlayDir);
  overlayFiles = map (v: overlayDir + ("/" + v)) overlayFileNames;
in
{
  pkgs ? import <nixpkgs> { overlays = map import overlayFiles; },
  lib ? pkgs.lib,
  mylib ? import ./lib.nix { inherit lib; },
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
in
lib.packagesFromDirectoryRecursive {
  callPackage = lib.callPackageWith packagesForCall;
  newScope = extra: lib.callPackageWith (lib.attrsets.unionOfDisjoint packagesForCall extra);
  directory = ./pkgs;
}
