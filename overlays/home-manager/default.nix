final: prev: {
  home-manager = prev.home-manager.overrideAttrs (oldAttrs: {
    patches =
      (oldAttrs.patches or [])
      # Add patches I've made / requested.
      ++ [
        # https://github.com/nix-community/home-manager/pull/5600
        ./repl.patch
        # https://github.com/nix-community/home-manager/pull/5576
        ./service-instance-restarts.patch
      ];
    postFixup =
      oldAttrs.postFixup
      + ''
        substituteInPlace $out/bin/home-manager \
          --replace-fail '<home-manager/home-manager/home-manager.nix>' ${./home-manager.nix}
      '';
  });
}
