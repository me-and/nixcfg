{ config, lib, pkgs, ... }:
let cfg = config.programs.git;
in {
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

  config = lib.mkIf (cfg.ref != null || cfg.rev != null) {
    programs.git.package = pkgs.callPackage ./package.nix {
      inherit (cfg) ref rev buildWithTests;
    };
  };
}
