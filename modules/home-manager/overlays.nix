{
  config,
  lib,
  ...
}: let
  # TODO Remove duplication of the below in modules/shared/overlays.nix
  thisRepoCleaned = lib.sources.cleanSourceWith {
    src = ../../.;
    # Filter out:
    # - All hidden files, including but not limited to the .git directory
    # - Any symlinks, as they're almost certainly symlinks to Nix build results
    # - The secrets directory, as that should never make it into the Nix store
    filter = path: type: let
      baseName = builtins.baseNameOf path;
    in
      (type != "symlink")
      && (baseName != "secrets")
      && ((builtins.match "\\..*" baseName) == null);
    name = "nixcfg";
  };
in {
  # Copy the local directory to the Nix store, and add a reference to the
  # overlays directory within to the NIX_PATH variable.  This means invocations
  # of commands like `nix-build` will find the overlays from the environment
  # per the most recent `home-manager switch` invocation.
  #
  # This based on
  # https://github.com/nix-community/home-manager/commit/8d5e27b4807d25308dfe369d5a923d87e7dbfda3
  options.nix.nixPath = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = [];
  };

  config.nix.nixPath = ["nixpkgs-overlays=${thisRepoCleaned}/overlays"];

  config.home.sessionVariables = lib.mkIf (config.nix.nixPath != []) {
    NIX_PATH = "${lib.strings.concatStringsSep ":" config.nix.nixPath}\${NIX_PATH:+:$NIX_PATH}";
  };
}
