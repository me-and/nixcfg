{
  git,
  lib,
  runCommand,
  rev ? null,
  ref ? "next",
  keepSrc ? true,
  doInstallCheck ? true,
  cacert,
  gitMinimal,
  gnumake,
  autoconf,
}: let
  rev' = rev;
in let
  gitHubRepo = "gitster/git";
  gitHubAPIInfo =
    builtins.fetchurl
    "https://api.github.com/repos/${gitHubRepo}/branches/${ref}";
  rev =
    if rev' == null
    then (builtins.fromJSON (builtins.readFile gitHubAPIInfo)).commit.sha
    else rev';

  # UUID randomly generated to make it possible to reliably find other Git
  # repos in the store, to speed up the fetch stage.
  srcUuid = "2ab053e6-dcf9-4b0d-aef2-c0d4f78bfc09";
  src =
    runCommand "git-src-${srcUuid}" {
      # Allow access outside the chroot jail to fetch the Git repository.
      __noChroot = true;
      # This script runs the configure script, so give it access to all the
      # tools that will be available at build time, plus cacert and
      # gitMinimal to do the cloning, as well as gitMinimal to be able to use
      # git-describe to compute a version number.
      nativeBuildInputs = [cacert gitMinimal];
    }
    # This includes a reference to the commit hash even though it's not always
    # necessary: doing this means the derivation will automatically be detected
    # as changed when the upstream commit changes.
    ''
      set -euo pipefail

      reference_args=()
      for ref in /nix/store/*-git-src-${srcUuid}/; do
          reference_args+=(--reference-if-able "$ref")
      done

      git clone --branch ${lib.escapeShellArg ref} \
          --single-branch \
          "''${reference_args[@]}" \
          --dissociate \
          --recurse-submodules \
          https://github.com/${lib.escapeShellArg gitHubRepo} $out
      cd $out
      git switch --detach --recurse-submodules ${lib.escapeShellArg rev}

      # Need to mark this as a safe directory for the version calculation
      # magic to work.
      HOME="$(mktemp -d)"
      export HOME
      git config --global safe.directory $out

      # Generate an imitation of the version file in official releases.
      ./GIT-VERSION-GEN
      version_file_contents="$(<GIT-VERSION-FILE)"
      version="''${version_file_contents#GIT_VERSION = }"
      printf '%s\n' "$version" >version
    '';

  gitOverridden = git.override {inherit doInstallCheck;};
in
  gitOverridden.overrideAttrs (oldAttrs: rec {
    inherit src;
    version = lib.fileContents "${src}/version";

    nativeBuildInputs = [autoconf] ++ oldAttrs.nativeBuildInputs;

    postPatch =
      if oldAttrs.doInstallCheck
      then oldAttrs.postPatch
      # No need to patch shebangs if we're not running the tests.
      else
        builtins.replaceStrings
        ["patchShebangs t/*.sh"] ["# patchShebangs t/*.sh"]
        oldAttrs.postPatch;

    # Make the configure script.  This isn't required for the release builds,
    # because they include a pre-built configure script, but the Git branches
    # don't include those files so they need making separately.  This based on
    # the contents of the make command in the buildPhase in the standard
    # builder.
    preConfigure = let
      # May or may not have Nixpkgs' 6bdfef9d2de2 (stdenv: generalize
      # _accumFlagsArray to concatTo, 2024-06-09)
      #
      # TODO Remove this once I only care about versions that have this patch,
      # which probably means once NixOS 24.11 is released and I've shifted all
      # my systems over to it.
      buildArrayCmd =
        if lib.versionAtLeast lib.version "24.11pre-git"
        then "concatTo flagsArray"
        else "_accumFlagsArray";
    in ''
      local flagsArray=(''${enableParallelBuilding:+-j''${NIX_BUILD_CORES}} SHELL=$SHELL)
      ${buildArrayCmd} makeFlags makeFlagsArray buildFlags buildFlagsArray
      echoCmd 'configure build flags' "''${flagsArray[@]}"
      make ''${makefile:+-f $makefile} "''${flagsArray[@]}" configure
      unset flagsArray
    '';
    configureFlags = ["--prefix=$out"] ++ oldAttrs.configureFlags;

    preInstallCheck =
      # https://github.com/NixOS/nixpkgs/pull/314258
      builtins.replaceStrings
      ["disable_test t1700-split-index"] [":"]
      oldAttrs.preInstallCheck;

    # If we want to keep the source in the store rather than allowing it to be
    # garbage collected (useful as it means the next fetch doesn't need to
    # download the entire Git source repository), add a symlink to the source
    # in the Nix store from the output.
    postInstall =
      oldAttrs.postInstall
      + lib.optionalString keepSrc ''
        ln -s ${src} $out/src
      '';
  })
