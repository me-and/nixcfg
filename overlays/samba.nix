# https://github.com/NixOS/nixpkgs/issues/502964
# https://github.com/NixOS/nixpkgs/pull/504784
final: prev: {
  samba = prev.samba.overrideAttrs (prevAttrs: {
    hardeningDisable =
      let
        prevOpt = prevAttrs.hardeningDisable or [ ];
      in
      if builtins.elem "strictflexarrays1" prevOpt then
        final.lib.warn "unnecessary samba overlay" prevOpt
      else
        prevOpt ++ [ "strictflexarrays1" ];
  });
}
