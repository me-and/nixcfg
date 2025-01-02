{
  config,
  lib,
  options,
  ...
}: let
  placeholderDefault = "_myModuleRename";
in {
  options.nix = {
    extraNixPaths = lib.mkOption {
      visible = false;
      default = placeholderDefault;
    };
    nixPaths = lib.mkOption {
      visible = false;
      default = placeholderDefault;
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
      nix.nixPath = ["nixpkgs-overlays=${overlayInfo.storeOverlayDir}"];
    };

    # This based reasonably heavily on the mkMergedOptionModule function in
    # nixpkgs' lib/modules.nix.
    optionImplementation = let
      cfg = config.nix;
    in {
      warnings = builtins.filter (x: x != "") (map (f: let
        val = lib.getAttrFromPath f config;
        opt = lib.getAttrFromPath f options;
      in
        lib.optionalString (val != placeholderDefault) ''
          The option ${lib.options.showOption f} defined in
          ${lib.options.showFiles opt.files} has been superseded by the Home
          Manager options nix.nixPath and nix.keepOldNixPath.  Please read the
          documentation for those options and update your configuration
          accordingly.
        '') [["nix" "extraNixPaths"] ["nix" "nixPaths"]]);

      nix.nixPath =
        (lib.optionals (cfg.extraNixPaths != placeholderDefault) cfg.extraNixPaths)
        ++ (lib.optionals (cfg.nixPaths != placeholderDefault) cfg.nixPaths);

      nix.keepOldNixPath =
        lib.mkIf (cfg.nixPaths != placeholderDefault) (cfg.nixPaths != null);
    };
  in
    lib.mkMerge [
      myConfig
      optionImplementation
    ];
}
