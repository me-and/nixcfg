{
  pkgs ? import <nixpkgs> {},
  lib ? pkgs.lib,
}: let
  myPackages = import ../pkgs {};
  freePackages =
    lib.filterAttrs
    (name: pkg: ! pkg.meta.unfree)
    myPackages;
in
  builtins.attrNames freePackages
