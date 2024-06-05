{ git, stdenv, lib, runCommandCC, rev ? null, ref ? null,
buildWithTests ?  true, cacert, gitMinimal, gnumake, autoconf }:
if (rev == null) && (ref == null) then git
else
  let
    gitHubRepo = "gitster/git";
    ref' = if ref == null then "master" else ref;
    gitHubAPIInfo = builtins.fetchurl "https://api.github.com/repos/${gitHubRepo}/branches/${ref'}";
    rev' = if rev == null then (builtins.fromJSON (builtins.readFile gitHubAPIInfo)).commit.sha else rev;
  in
    git.overrideDerivation (oldAttrs: rec {
      # UUID randomly generated to make it possible to reliably find other Git
      # repos in the store, to speed up the fetch stage.
      src = runCommandCC "git-src-2ab053e6-dcf9-4b0d-aef2-c0d4f78bfc09" {
          # Allow access outside the chroot jail to fetch the Git repository.
          __noChroot = true;
          # This script runs the configure script, so give it access to all the
          # tools that will be available at build time, plus cacert and
          # gitMinimal (to do the cloning) and autoconf (to create the
          # configure script).
          nativeBuildInputs = oldAttrs.nativeBuildInputs ++ [ cacert gitMinimal autoconf ];
        }
        ''
          set -euo pipefail

          references=(/nix/store/*-git-src-2ab053e6-dcf9-4b0d-aef2-c0d4f78bfc09/)
          reference_args=()
          for ref in "''${references[@]}"; do
              reference_args+=(--reference-if-able "$ref")
          done

          # Need to mark this as a safe directory for the version calculation
          # magic to work.
          HOME="$(mktemp -d)"
          export HOME
          git config --global safe.directory '*'

          git clone --branch ${lib.escapeShellArg ref'} \
              --single-branch \
              "''${reference_args[@]}" \
              --dissociate \
              --recurse-submodules \
              https://github.com/${lib.escapeShellArg gitHubRepo} $out
          cd $out
          git switch --detach ${lib.escapeShellArg rev'}

          # Run this here to get the version info, and to match how things are
          # handled in the upstream release bundles (which means the configure
          # stage isn't run as part of the original Nix build stage).
          make configure
          ./configure
        '';
      version = lib.removePrefix
        "GIT_VERSION = "
        (lib.fileContents "${src}/GIT-VERSION-FILE");
      installCheckTarget =
        if buildWithTests then oldAttrs.installCheckTarget else null;
      preInstallCheck =
        # https://github.com/NixOS/nixpkgs/pull/314258
        (builtins.replaceStrings
          ["disable_test t1700-split-index"] [":"]
          oldAttrs.preInstallCheck
        )
        # https://github.com/NixOS/nixpkgs/commit/150cd0ab619dae2da2fc7f8d8478000571e1717d
        + ''
          disable_test t9902-completion
        '';
      postPatch =
        if buildWithTests
        then oldAttrs.postPatch
        # No need to patch shebangs if we're not running the tests.
        else builtins.replaceStrings ["patchShebangs t/*.sh"] ["# patchShebangs t/*.sh"] oldAttrs.postPatch;
      nativeBuildInputs = oldAttrs.nativeBuildInputs;
    })
