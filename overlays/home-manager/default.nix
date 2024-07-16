# Pull in the changes from my PR:
# https://github.com/nix-community/home-manager/pull/5600
final: prev: {
  home-manager = prev.home-manager.overrideAttrs (oldAttrs: {
    patches = (oldAttrs.patches or []) ++ [./repl.patch];
    postFixup =
      oldAttrs.postFixup
      + ''
        substituteInPlace $out/bin/home-manager \
          --replace-fail '<home-manager/home-manager/home-manager.nix>' ${./home-manager.nix}
      '';
  });
}
