# https://github.com/NixOS/nixpkgs/pull/347497
final: prev: {
  git-credential-manager = prev.git-credential-manager.overrideAttrs (prevAttrs: {
    makeWrapperArgs =
      if builtins.elem "--inherit-argv0" prevAttrs.makeWrapperArgs
      then prevAttrs.makeWrapperArgs
      else prevAttrs.makeWrapperArgs ++ ["--inherit-argv0"];
  });
}