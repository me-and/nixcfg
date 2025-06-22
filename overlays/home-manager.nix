final: prev: {
  home-manager = prev.home-manager.overrideAttrs (prevAttrs: {
    # Home Manager references its own source directory when it's looking for
    # *.nix files, so for my patches to take effect, I need to apply them to
    # the source directory before any of the building takes place: applying
    # them as part of the home-manager derivation patch phase is too late,
    # since Home Manager will continue to reference the unpatched files from
    # the source directory.
    src = final.applyPatches {
      src = prevAttrs.src;

      # https://github.com/nix-community/home-manager/pull/5600
      # Add a `home-manager repl` command.
      patches = final.fetchGitHubPatch {
        owner = "nix-community";
        repo = "home-manager";
        commit = "b7e5223b0b25c3fcdb3937df160e7b5efccd2dfb";
        hash = "sha256-+EHrAu+CggJWDqnnrn2VlUN4HNsD96QXo+D6CAzAqDo=";
      };
    };
  });
}
