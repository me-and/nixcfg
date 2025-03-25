{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.programs.mypy;
in {
  options.programs.mypy = {
    enable = lib.mkEnableOption "mypy";
    package = lib.mkPackageOption pkgs "mypy" {};
    config = lib.mkOption {
      description = "Configuration for mypy";
      default = {};
      example = {
        mypy = {
          warn_return_any = true;
          warn_unused_configs = true;
        };
        "mypy-mycode.foo.*" = {
          disallow_untyped_defs = true;
        };
        "mypy-mycode.bar" = {
          warn_return_any = false;
        };
        "mypy-somelibrary" = {
          ignore_missing_imports = true;
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [cfg.package];
    xdg.configFile = let
    in
      lib.mkIf (cfg.config != {}) {
        "mypy/config".text =
          lib.generators.toINI {
            mkKeyValue = lib.generators.mkKeyValueDefault {
              mkValueString = v:
                if v == true
                then "True"
                else if v == false
                then "False"
                else lib.generators.mkValueStringDefault {} v;
            } " = ";
          }
          cfg.config;
      };
  };
}
