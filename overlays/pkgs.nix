# This file based heavily on <nixpkgs/pkgs/top-level/by-name-overlay.nix>
#
# This file needs to work without importing the pkgs directly as a whole, since
# pkgs/default.nix depends on overlays.  It can also only use `lib` from `prev`
# for computing the names of the things being overridden, as otherwise Nix
# can't tell if one of the values being overridden in `final` is `lib` itself.
final: prev: let
  inherit (prev.lib.attrsets) mapAttrs filterAttrs;
  inherit (prev.lib) path;
  inherit (builtins) readDir pathExists;

  pkgDir = ../pkgs;
  possiblePackageFiles =
    mapAttrs
    (name: _: path.append pkgDir "${name}/package.nix")
    (readDir pkgDir);
  packageFiles =
    filterAttrs
    (_: value: pathExists value)
    possiblePackageFiles;
in
  mapAttrs (name: value: final.callPackage value {}) packageFiles
