final: prev: let
  inherit (final) patch patchutils writeShellApplication;
in {
  taskserver = let
    version = "1.2.0";
  in
    prev.taskserver.overrideAttrs (oldAttrs: {
      inherit version;
      # The upstream repository has a now-dead URL for the submodule.  The
      # submodule is now available on GitHub, so wrap Git with a version that
      # includes rewriting the URL for the submodule.
      src = let
        git = writeShellApplication {
          name = "git";
          text = ''
            ${final.git}/bin/git \
                -c 'url.https://github.com/GothenburgBitFactory/.insteadOf=https://git.tasktools.org/scm/tm/' \
                "$@"
          '';
        };
        fetchgit = final.fetchgit.override {inherit git;};
        fetchFromGitHub = final.fetchFromGitHub.override {inherit fetchgit;};
      in
        fetchFromGitHub {
          owner = "GothenburgBitFactory";
          repo = "taskserver";
          # Use this revision because it contains the fix I care about for
          # durations specified in weeks, and doesn't hit the permissions error
          # on startup that I haven't managed to debug but do hit on the tip of
          # the v1.2.0 branch.
          rev = "333bee7b04adf00d0b68480342eec3a46ef0949f";
          fetchSubmodules = true;
          hash = "sha256-SBL1DWvUKJufd46GW3++kB7F0miw8MW/7vRr4cZsJgw=";
        };

      # Revert the patch that requires a config file, because Nix's approach is
      # to set all the config on the command line.
      #
      # TODO Work out a better way to apply this patch; I think the original
      # patch phase is a bit shonky too, as it doesn't seem to have the hooks
      # I'd expect.  I suspect I want to delete the patchPhase attr (is that
      # possible in an override?) and put their patchPhase code in a
      # post-patch hook.
      patchPhase = let
        patchFile = final.fetchGitHubPatch {
          owner = "GothenburgBitFactory";
          repo = "taskserver";
          commit = "bbd42468d284a3a954bdb233211a17b598036e98";
          hash = "sha256-518qF8ui5GMmsdQRTm75zrBgMhlhB7ffi3B+plzlWKQ=";
        };
      in
        # Don't patch the changelog, partly because we don't need to, and
        # partly because the patch doesn't apply.
        ''
          ${patchutils}/bin/filterdiff -x '*/ChangeLog' ${patchFile} |
              ${patch}/bin/patch -R -p1
        ''
        + oldAttrs.patchPhase;
    });
}
