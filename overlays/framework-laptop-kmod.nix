# https://github.com/NixOS/nixpkgs/pull/575818
final: prev:
let
  inherit (final) lib;
in
{
  linuxPackages = prev.linuxPackages.extend (
    linuxfinal: linuxprev: {
      framework-laptop-kmod = linuxprev.framework-laptop-kmod.overrideAttrs (
        prevAttrs:
        lib.warnIf (prevAttrs.installPhase or null == null)
          "possibly unnecessary framework-laptop-kmod package"
          {
            makeFlags = prevAttrs.makeFlags ++ [
              "INSTALL_MOD_PATH=${placeholder "out"}"
              "INSTALL_MOD_DIR=extra"
              "DEPMOD=true"
            ];
            installTargets = [ "modules_install" ];
            installPhase = null;
          }
      );
    }
  );
}
