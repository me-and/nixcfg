# https://github.com/NixOS/nixpkgs/pull/493978
final: prev:
let
  inherit (final) fetchpatch;
  inherit (final.lib)
    any
    baseNameOf
    warn
    versionAtLeast
    ;
in
{
  freecad = prev.freecad.overrideAttrs (prevAttrs: {
    patches =
      if
        any (f: baseNameOf f == "0004-FreeCad-fix-boost-189-build.patch") prevAttrs.patches
        || versionAtLeast prevAttrs.version "1.1"
      then
        warn "unnecessary freecad overlay" prevAttrs.patches
      else
        prevAttrs.patches
        ++ [
          (fetchpatch {
            name = "0004-FreeCad-fix-boost-189-build.patch";
            url = "https://raw.githubusercontent.com/NixOS/nixpkgs/405bc0e9e6a87e92326a5fc16b4b0d24e31d7e87/pkgs/by-name/fr/freecad/0004-FreeCad-fix-boost-189-build.patch";
            hash = "sha256-XRiHsdeQKxC52G447wQHYcylcSdRKxp7tG2kFrLNV0s=";
          })
        ];
  });
}
