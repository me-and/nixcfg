{
  config,
  lib,
  ...
}: {
  options.nix = {
    extraNixPaths = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      description = ''
        Extra path entries to add to the NIX_PATH variable when initialising
        Home Manager session environment variables.  These paths will be added
        before any paths that are set by the parent environment or using the
        nix.nixPaths configuration.
      '';
      example = ["nixpkgs-overlays=\${config.home.homeDirectory}/my-overlays"];
      default = [];
    };
    nixPaths = lib.mkOption {
      type = lib.types.nullOr (lib.types.listOf lib.types.str);
      description = ''
        Paths to set in the NIX_PATH variable when initialising Home Manager
        session environment variables.  These paths will be added after any
        paths configured using nix.extraNixPaths, and will overwrite any
        environment variables set in the parent environment.

        Set to to `null` to inherit the parent environment's NIX_PATH, or to
        `[]` to set the path to the empty string.
      '';
      default = null;
    };
  };

  config = let
    # Copy the local directory to the Nix store, and add a reference to the
    # overlays directory within to the NIX_PATH variable.  This means
    # invocations of commands like `nix-build` will find the overlays from the
    # environment per the most recent `home-manager switch` invocation.
    #
    # This based on
    # https://github.com/nix-community/home-manager/commit/8d5e27b4807d25308dfe369d5a923d87e7dbfda3
    myConfig = let
      overlayInfo = import ../../lib/overlays.nix {inherit lib;};
    in {
      nix.nixPaths = ["nixpkgs-overlays=${overlayInfo.storeOverlayDir}"];
    };

    optionImplementation = let
      cfg = config.nix;
    in {
      home.sessionVariables =
        if cfg.nixPaths == null && cfg.extraNixPaths == []
        then {}
        else if cfg.nixPaths == null
        then {
          NIX_PATH = "${lib.strings.concatStringsSep ":" cfg.extraNixPaths}\${NIX_PATH:+:$NIX_PATH}";
        }
        else {
          NIX_PATH = lib.strings.concatStringsSep ":" (cfg.extraNixPaths ++ cfg.nixPaths);
        };
      };
  in
    lib.mkMerge [
      myConfig
      optionImplementation
    ];
}
