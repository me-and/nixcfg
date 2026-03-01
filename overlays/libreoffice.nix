# https://github.com/NixOS/nixpkgs/pull/494721
final: prev:
let
  inherit (final.lib) map warn all;
  inherit (final) noto-fonts;
in
{
  libreoffice = prev.libreoffice.override {
    unwrapped = prev.libreoffice.passthru.unwrapped.overrideAttrs (prevAttrs: {
      env = prevAttrs.env // {
        FONTCONFIG_FILE = prevAttrs.env.FONTCONFIG_FILE.overrideAttrs (prevFontAttrs: {
          fontDirectories =
            if all (d: d.name != "noto-fonts-subset") prevFontAttrs.fontDirectories
            then warn "unnecessary libreoffice overlay" prevFontAttrs.fontDirectories
            else map (d: if d.name == "noto-fonts-subset" then noto-fonts else d) prevFontAttrs.fontDirectories;
        });
      };
    });
  };
}
