final: prev: {
  home-manager = prev.home-manager.overrideAttrs (prevAttrs: {
    # Home Manager references its own source directory when it's looking for
    # *.nix files, so for my patches to take effect, I need to apply them to
    # the source directory before any of the building takes place: applying
    # them as part of the home-manager derivation patch phase is too late,
    # since Home Manager will continue to reference the unpatched files from
    # the source directory.
    #
    # TODO is this true and relevant for *both* my patches?
    src = final.applyPatches {
      src = prevAttrs.src;
      patches = let
        patch = p:
          final.fetchGitHubPatch (
            {
              owner = "nix-community";
              repo = "home-manager";
            }
            // p
          );

        # https://github.com/nix-community/home-manager/pull/5600
        # Add a `home-manager repl` command.
        replPatch = patch {
          commit = "77326d1a2e45cdf40570ad102abca3e442d2d4b2";
          hash = "sha256-14JN5MGDjntDHnm9s0m5kJPr7KmBcylz+UWPIsLjE9U=";
        };

        # https://github.com/nix-community/home-manager/pull/5576
        # Silence warnings about systemd template files during activation.
        systemdTemplatesPatch =
          patch
          {
            commit = "607f969f5dca2dc100cbc53e24ab49ac24ef8987";
            hash = "sha256-GPTCyNIVDGMHJLzv6MM0hUzmTgqfqj/6BxjZNfvVqb4=";
          };
        systemdTemplatesPatchNeeded =
          final.lib.versionOlder prevAttrs.version "0-unstable-2024-06-26";
        systemdTemplatesPatchWarning =
          final.lib.warnIf (final.lib.oldestSupportedReleaseIsAtLeast 2411)
          ''
            home-manager patch for systemd template files in
            ${builtins.toString ./.}/home-manager.nix can safely be removed.
          '';
      in
        [replPatch]
        ++ (
          final.lib.optional
          (systemdTemplatesPatchWarning systemdTemplatesPatchNeeded)
          systemdTemplatesPatch
        );
    };
  });
}
