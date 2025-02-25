# https://github.com/NixOS/nixpkgs/pull/381549
final: prev: let
  lib = final.lib;
in {
  azuredatastudio =
    lib.warnIf (lib.oldestSupportedReleaseIsAtLeast 2505)
    ''
      Unnecessary patching of azuredatastudio package in
      ${./.}/azuredatastudio.nix
    ''
    prev.azuredatastudio.overrideAttrs (
      prevAttrs:
        if builtins.hasAttr "fixupPhase" prevAttrs
        then {
          nativeBuildInputs = (prevAttrs.nativeBuildInputs or []) ++ [final.wrapGAppsHook3];
          preFixup = prevAttrs.fixupPhase;
          # The one thing that fixupPhase-as-a-variable should do is call
          # fixupPhase-as-a-function.
          fixupPhase = "fixupPhase";
        }
        else {}
    );
}
