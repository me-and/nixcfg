# https://github.com/NixOS/nixpkgs/pull/493831
final: prev: {
  makemkv = prev.makemkv.overrideAttrs (prevAttrs: {
    buildInputs =
      if builtins.elem final.expat prevAttrs.buildInputs then
        final.lib.warn "unnecessary makemvk overlay" prevAttrs.buildInputs
      else
        [ final.expat ] ++ prevAttrs.buildInputs;
  });
}
