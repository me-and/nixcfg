# https://github.com/NixOS/nixpkgs/pull/381549
final: prev: {
  azuredatastudio = prev.azuredatastudio.overrideAttrs (prevAttrs: {
    nativeBuildInputs = (prevAttrs.nativeBuildInputs or []) ++ [final.wrapGAppsHook3];
    preFixup = prevAttrs.fixupPhase;
    # The one thing that fixupPhase-as-a-variable should do is call
    # fixupPhase-as-a-function.
    fixupPhase = "fixupPhase";
  });
}
