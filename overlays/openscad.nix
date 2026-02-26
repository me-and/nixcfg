# https://github.com/NixOS/nixpkgs/pull/493813
final: prev:
let
  inherit (final) fetchpatch;
  inherit (final.lib) any baseNameOf warn;
in
{
  openscad = prev.openscad.overrideAttrs (prevAttrs: {
    patches =
      if any (f: baseNameOf f == "boost-1.89.patch") prevAttrs.patches then
        warn "unnecessary openscad overlay" prevAttrs.patches
      else
        prevAttrs.patches
        ++ [
          (fetchpatch {
            name = "boost-1.89.patch";
            url = "https://raw.githubusercontent.com/NixOS/nixpkgs/877b2ba20358c54b27861fb4c0db085b29af8d5e/pkgs/by-name/op/openscad/boost-1.89.patch";
            hash = "sha256-T/duWoPfRhJdfAcmgHKkEe4bvZyUnb6pIe2iLFVD+Pk=";
          })
        ];
  });
}
