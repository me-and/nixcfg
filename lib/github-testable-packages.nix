# Filter the list of packages to only provide the names of ones that can be
# built as part of GitHub actions.  Assume a package can be built unless (a)
# meta.buildOnGitHub is defined and false, or (b) meta.buildOnGitHub is not
# defined but meta.platforms is and doesn't include the build platform.
#
# This emulates the meta.hydraPlatforms interface used by the Nixpkgs repository.
let
  overlayDir = ../overlays;
  overlayFileNames = builtins.attrNames (builtins.readDir overlayDir);
  overlayFiles = map (v: overlayDir + ("/" + v)) overlayFileNames;
in
  {
    pkgsPath ? <nixpkgs>,
    pkgs ? import pkgsPath {overlays = map import overlayFiles;},
    lib ? pkgs.lib,
  }: let
    packages = import ../pkgs {inherit pkgsPath pkgs lib;};

    buildPackage = package:
      if package ? meta
      then
        if package.meta ? buildOnGitHub
        then package.meta.buildOnGitHub
        else if package.meta ? platforms
        then builtins.elem builtins.currentSystem package.meta.platforms
        else true
      else true;

    buildablePackages = lib.filterAttrs (n: v: buildPackage v) packages;
  in
    builtins.attrNames buildablePackages
