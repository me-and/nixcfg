{ git, lib, runCommand, rev ? null, ref ? null,
buildWithTests ? true, cacert, gitMinimal, gnumake, autoconf }:
let
  gitHubRepo = "gitster/git";
  ref' = if ref == null then "master" else ref;
  gitHubAPIInfo = builtins.fetchurl "https://api.github.com/repos/${gitHubRepo}/branches/${ref'}";
  rev' = if rev == null then (builtins.fromJSON (builtins.readFile gitHubAPIInfo)).commit.sha else rev;

  # UUID randomly generated to make it possible to reliably find other Git
  # repos in the store, to speed up the fetch stage.
  srcUuid = "2ab053e6-dcf9-4b0d-aef2-c0d4f78bfc09";
  src = runCommand "git-src-${srcUuid}" {
      # Allow access outside the chroot jail to fetch the Git repository.
      __noChroot = true;
      # This script runs the configure script, so give it access to all the
      # tools that will be available at build time, plus cacert and
      # gitMinimal to do the cloning, as well as gitMinimal to be able to use
      # git-describe to compute a version number.
      nativeBuildInputs = [ cacert gitMinimal ];
    }
    ''
      set -euo pipefail

      reference_args=()
      for ref in /nix/store/*-git-src-${srcUuid}/; do
          reference_args+=(--reference-if-able "$ref")
      done

      git clone --branch ${lib.escapeShellArg ref'} \
          --single-branch \
          "''${reference_args[@]}" \
          --dissociate \
          --recurse-submodules \
          https://github.com/${lib.escapeShellArg gitHubRepo} $out
      cd $out
      git switch --detach ${lib.escapeShellArg rev'}

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
in
git.overrideAttrs (oldAttrs: rec {
  inherit src;
  version = lib.fileContents "${src}/version";

  # Make the configure script.  This isn't required for the release builds,
  # because they include a pre-built configure script, but the Git branches
  # don't include those files so they need making separately.  This based on
  # the contents of the make command in the buildPhase in the standard
  # builder.
  preConfigure = ''
    local flagsArray=(''${enableParallelBuilding:+-j''${NIX_BUILD_CORES}} SHELL=$SHELL)
    _accumFlagsArray makeFlags makeFlagsArray buildFlags buildFlagsArray
    echoCmd 'configure build flags' "''${flagsArray[@]}"
    make ''${makefile:+-f $makefile} "''${flagsArray[@]}" configure
    unset flagsArray
  '';
  configureFlags = [ "--prefix=$out" ] ++ oldAttrs.configureFlags;

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
  nativeBuildInputs = [ autoconf ] ++ oldAttrs.nativeBuildInputs;
})
