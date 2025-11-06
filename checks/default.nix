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
  mypkgs ? import ../pkgs {
    inherit
      lib
      mylib
      overlays
      pkgs
      ;
  },
}:
let
  testFiles = mylib.dirfiles {
    dir = ./.;
    excludes = [ "default.nix" ];
  };
  callPackage = lib.callPackageWith {
    inherit
      lib
      pkgs
      mylib
      mypkgs
      ;
  };
in
builtins.mapAttrs (n: v: callPackage v { }) testFiles
