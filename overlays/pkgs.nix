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

  packageFiles = (import ../lib/subdirfiles.nix) prev.lib ../pkgs "package.nix";
  hiddenPackageWarning = pkgName: ''
    Package ${pkgName} exists in nixpkgs but is being overwritten by a local
    package.
  '';
  fileAttrToPackage = name: value:
    prev.lib.warnIf
    (
      (builtins.hasAttr name prev)
      && (builtins.tryEval prev."${name}").success
    )
    (hiddenPackageWarning name)
    (final.callPackage value {});
in
  mapAttrs fileAttrToPackage packageFiles
