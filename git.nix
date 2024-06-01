{ pkgs, config, lib, ... }:
let
  cfg = config.programs.git;

  gitFromSource = pkgs.git.overrideAttrs (oldAttrs:
    let
      gitHubAPIInfo = builtins.fetchurl
        "https://api.github.com/repos/gitster/git/branches/${cfg.sourceBranch}";
      rev = (builtins.fromJSON (builtins.readFile (gitHubAPIInfo))).commit.sha;
    in rec {
      # UUID randomly generated to make it possible to reliably find other Git
      # repos in the store, to speed up the fetch stage.
      src = pkgs.runCommand "git-src-2ab053e6-dcf9-4b0d-aef2-c0d4f78bfc09" {
          __noChroot = true;  # Allow the remote fetching
          nativeBuildInputs = [ pkgs.cacert pkgs.gitMinimal pkgs.gnumake ];
          dummyRev = rev;  # Force rebuild when the rev changes.
        }
        ''
          set -euo pipefail

          references=(/nix/store/*-git-src-2ab053e6-dcf9-4b0d-aef2-c0d4f78bfc09/)
          reference_args=()
          for ref in "''${references[@]}"; do
              reference_args+=(--reference "$ref")
          done

          # Need to mark this as a safe directory for the version calculation
          # magic to work.
          HOME="$(mktemp -d)"
          export HOME
          git config --global safe.directory '*'

          git clone --branch ${lib.escapeShellArg cfg.sourceBranch} \
              --single-branch \
              "''${reference_args[@]}" \
              --dissociate \
              --recurse-submodules \
              https://github.com/gitster/git $out
          cd $out
          make GIT-VERSION-FILE
        '';
      version = lib.removePrefix
        "GIT_VERSION = "
        (lib.fileContents "${src}/GIT-VERSION-FILE");
      installCheckTarget =
        if cfg.buildWithTests then oldAttrs.installCheckTarget else null;
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

      # I want to run configure locally, not rely on the upstream version, if it
      # even exists.
      postPatch = ''
        make prefix=$out configure
        ./configure
      '' + oldAttrs.postPatch;
      nativeBuildInputs = oldAttrs.nativeBuildInputs ++ [ pkgs.autoconf ];
    });
in
{
  options = {
    programs.git.sourceBranch = lib.mkOption {
      default = null;
      type = lib.types.nullOr lib.types.str;
      example = "master";
      description = lib.mdDoc ''
        The name of the branch to build from.
      '';
    };

    programs.git.buildWithTests = lib.mkOption {
      default = true;
      type = lib.types.bool;
      example = false;
      description = lib.mdDoc ''
        Whether to run the tests while building.
      '';
    };
  };

  config.programs.git.package =
    if cfg.sourceBranch == null
    then pkgs.git
    else gitFromSource;

  # This only works for the first build *after* the one where it's required.
  # For that first build, use `sudo nixos-rebuild --option sandbox relaxed
  # (test|switch|boot)`.
  config.nix.settings = lib.optionalAttrs (cfg.sourceBranch != null) {
    sandbox = "relaxed";
  };
}
