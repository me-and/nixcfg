final: prev: {
  nix-index-unwrapped = prev.nix-index-unwrapped.overrideAttrs (prevAttrs: {
    patches = (prev.patches or []) ++ [./newline.diff];
  });
}
