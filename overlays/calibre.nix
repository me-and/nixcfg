# https://github.com/NixOS/nixpkgs/issues/493843#issuecomment-3956990127
# https://github.com/NixOS/nixpkgs/pull/493988
final: prev: {
  calibre =
    if final.lib.hasInfix "@qtbaseOut@" final.qt6.qtbase.postFixup then
      final.lib.warn "unnecessary calibre overlay" prev.calibre
    else
      prev.calibre.overrideAttrs (prevAttrs: {
        preInstall = prevAttrs.preInstall or "" + ''
          export QMAKE=${final.qt6.qtbase}/bin/qmake
        '';
      });
}
