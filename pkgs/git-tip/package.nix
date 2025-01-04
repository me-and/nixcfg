{
  git,
  lib,
  runCommand,
  rev ? null,
  ref ? "next",
  tag ? false,
  srcPath ? null,
  keepSrc ? true,
  doInstallCheck ? true,
  cacert,
  gitMinimal,
  autoconf,
  openssl,
  zlib,
  curl,
  stdenv,
}: let
  rev' = rev;
in let
  gitHubRepo = "gitster/git";

  rev = let
    tagAPIInfo =
      builtins.fetchurl
      "https://api.github.com/repos/${gitHubRepo}/tags";
    tagInfo =
      lib.lists.findSingle
      (info: info.name == ref)
      (throw "no git tag named ${ref} found")
      (throw "multiple git tags named ${ref} found!?")
      (builtins.fromJSON (builtins.readFile tagAPIInfo));
    branchAPIInfo =
      builtins.fetchurl
      "https://api.github.com/repos/${gitHubRepo}/branches/${ref}";
    branchInfo =
      builtins.fromJSON (builtins.readFile branchAPIInfo);
  in
    if rev' != null
    then rev'
    else if tag
    then tagInfo.commit.sha
    else branchInfo.commit.sha;

  # Stage one of two in preparing the source code: check out the version we've
  # been asked for.  This is implemented directly in part to allow it to be
  # horrendously impure by looking at what the latest release is online, and
  # partly to allow us to keep the local .git directory *and to reference
  # previous clones in new ones* to speed up the git clone process.
  #
  # UUID randomly generated to make it possible to reliably find other Git
  # repos in the store, to speed up the fetch stage.
  srcUuid = "2ab053e6-dcf9-4b0d-aef2-c0d4f78bfc09";
  srcSrc =
    if srcPath != null
    then srcPath
    else
      runCommand "git-src-${srcUuid}" {
        # Allow access outside the chroot jail to speed up fetching the Git
        # repository based on previous fetches.
        __noChroot = true;

        # Provide a git command to be able to do the clone.
        nativeBuildInputs = [gitMinimal cacert];
      }
      ''
        set -euo pipefail

        # Avoid spurious "detached head" warnings.
        git () {
            command git -c advice.detachedHead=false "$@"
        }

        reference_args=()
        for repo in /nix/store/*-git-src-${srcUuid}/; do
            reference_args+=(--reference-if-able "$repo")
        done

        git clone --branch ${lib.escapeShellArg ref} \
            --single-branch \
            "''${reference_args[@]}" \
            --dissociate \
            --recurse-submodules \
            https://github.com/${lib.escapeShellArg gitHubRepo} "$out"

        # This step is frequently unnecessary, but it means we always have a
        # reference to the commit hash, so the derivation will inherently change
        # if and when the branch points to a different target.
        git -C "$out" switch --detach --recurse-submodules ${lib.escapeShellArg rev}
      '';

  # Stage two of two in preparing the source code: create a distribution
  # tarball.  This creates a tarball more-or-less identical to the one that's
  # created for full Git version releases, which means it can be used with the
  # nixpkgs git packaging code that assumes the source package will contain
  # some of the extras that are included in the release tarball and aren't in
  # the bare repository.
  #
  # Building the tarball does do some actual C building, so there are a bunch
  # of depedencies that ideally wouldn't be needed until the final, real,
  # build.
  src = stdenv.mkDerivation {
    name = "git-source.tar.gz";
    src = srcSrc;
    outputs = ["out" "ver"] ++ lib.optional keepSrc "srcsrc";
    nativeBuildInputs = [gitMinimal openssl zlib curl autoconf];
    enableParallelBuilding = true;
    dontPatch = true;
    dontConfigure = true;
    buildFlags = ["dist"];
    installPhase =
      ''
        runHook preInstall

        tarballs=(git-*.tar.gz)
        if (( "''${#tarballs[*]}" != 1 )); then
            echo 'Unexpected number of build tarballs!' >&2
            exit 1
        fi

        v="''${tarballs[0]}"
        v="''${v%.tar.gz}"
        v="''${v#git-}"
        echo "$v" >"$ver"
        mv "''${tarballs[0]}" "$out"

      ''
      # If we want to keep the source in the store rather than allowing it to be
      # garbage collected (useful as it means the next fetch doesn't need to
      # download the entire Git source repository), add a symlink to the source
      # in the Nix store from the output.
      + lib.optionalString keepSrc ''
        ln -s ${srcSrc} "$srcsrc"

      ''
      + ''
        runHook postInstall
      '';
    dontFixup = true;
  };

  gitOverridden = git.override {inherit doInstallCheck;};
in
  gitOverridden.overrideAttrs (finalAttrs: oldAttrs: {
    inherit src;
    version = lib.fileContents src.ver;

    postPatch =
      if finalAttrs.doInstallCheck
      then oldAttrs.postPatch
      # No need to patch shebangs if we're not running the tests.
      else
        builtins.replaceStrings
        ["patchShebangs t/*.sh"] ["# patchShebangs t/*.sh"]
        oldAttrs.postPatch;

    # The below for https://github.com/NixOS/nixpkgs/pull/370888, except where
    # commented...
    enableParallelInstalling = true;
    postBuild =
      ''
        local flagsArray=(
            ''${enableParallelBuilding:+-j''${NIX_BUILD_CORES}}
            SHELL="$SHELL"
        )
        concatTo flagsArray makeFlags makeFlagsArray buildFlags buildFlagsArray
        if [[ "$(type -t make)" != file ]]; then
            echo "make isn't a file to be executed!" >&2
            type make
            exit 1
        fi
        make () {
            command make "''${flagsArray[@]}" "$@"
        }
        make -C Documentation
        make -C contrib/subtree all doc
      ''
      + (oldAttrs.postBuild or "")
      + ''
        unset flagsArray
        unset -f make
      '';

    postInstall =
      ''
        local flagsArray=(
            ''${enableParallelBuilding:+-j''${NIX_BUILD_CORES}}
            SHELL="$SHELL"
        )
        concatTo flagsArray makeFlags makeFlagsArray installFlags installFlagsArray
        if [[ "$(type -t make)" != file ]]; then
            echo "make isn't a file to be executed!" >&2
            type make
            exit 1
        fi
        make () {
            command make "''${flagsArray[@]}" "$@"
        }
      ''
      + (oldAttrs.postInstall or "")
      + ''
        unset flagsArray
        unset -f make
      ''
      # If we want to keep the source in the store rather than allowing it to
      # be garbage collected (useful as it means the next fetch doesn't need to
      # download the entire Git source repository), add a symlink to the source
      # in the Nix store from the output.
      + lib.optionalString keepSrc ''
        ln -s ${src.srcsrc} $out/src
      '';
  })
