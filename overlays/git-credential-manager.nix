# https://github.com/NixOS/nixpkgs/pull/347497
final: prev: {
  git-credential-manager = prev.git-credential-manager.overrideAttrs (prevAttrs: {
    makeWrapperArgs = prevAttrs.makeWrapperArgs ++ ["--inherit-argv0"];
  });
}
