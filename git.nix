{ config, lib, pkgs, ... }:
let
  cfg = config.programs.git;

  gitFromSource = pkgs.git.overrideAttrs (oldAttrs:
    let
      gitHubRepo = "gitster/git";
      gitHubAPIInfo = builtins.fetchurl
        "https://api.github.com/repos/${gitHubRepo}/branches/${cfg.ref}";
      rev =
        if cfg.rev == null
        then (builtins.fromJSON (builtins.readFile (gitHubAPIInfo))).commit.sha
        else cfg.rev;
    in rec {
      # UUID randomly generated to make it possible to reliably find other Git
      # repos in the store, to speed up the fetch stage.
      src = pkgs.runCommand "git-src-2ab053e6-dcf9-4b0d-aef2-c0d4f78bfc09" {
          __noChroot = true;  # Allow the remote fetching
          nativeBuildInputs = [ pkgs.cacert pkgs.gitMinimal pkgs.gnumake ];
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

          git clone --branch ${lib.escapeShellArg cfg.ref} \
              --single-branch \
              "''${reference_args[@]}" \
              --dissociate \
              --recurse-submodules \
              https://github.com/${lib.escapeShellArg gitHubRepo} $out
          cd $out
          git switch --detach ${lib.escapeShellArg rev}
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
    programs.git.ref = lib.mkOption {
      default = null;
      type = lib.types.nullOr lib.types.str;
      example = "master";
      description = "The name of the branch or tag to build from.";
    };

    programs.git.rev = lib.mkOption {
      default = null;
      type = lib.types.nullOr lib.types.str;
      example = "51c0d632d3b6f489f60f2f19f0e8107318335085";
      description = ''
        The name of the revision to build from.  If this is
        specified and it isn't reachable from the master branch, you must also
        specify the branch to clone to be able to check this revision out.
      '';
    };

    programs.git.buildWithTests = lib.mkOption {
      default = true;
      type = lib.types.bool;
      example = false;
      description = "Whether to run the tests while building.";
    };
  };

  config = lib.mkIf (cfg.ref != null) {
    programs.git.package = gitFromSource;
  };
}
