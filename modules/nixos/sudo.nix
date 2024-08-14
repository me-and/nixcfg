{
  config,
  lib,
  ...
}: let
  cfg = config.security.sudo;
in {
  options.security.sudo.preserveEnvVars = lib.mkOption {
    description = ''
      What environment variables to preserve when using sudo as `root` or as
      the `wheel` group.
    '';
    type = lib.types.listOf (lib.types.strMatching "[^=\" ]*");
    default = [];
  };

  config = let
    implementationConfig = lib.mkIf (cfg.preserveEnvVars != []) {
      security.sudo.extraConfig =
        ''
          # Preserve environment variables for root and %wheel
        ''
        + lib.concatLines (
          map (var: "Defaults:root,%wheel env_keep+=${var}")
          cfg.preserveEnvVars
        );
    };

    myConfig = {
      security.sudo.preserveEnvVars = [
        "VISUAL"
        "EDITOR"
        "SYSTEMD_EDITOR"
        "SUDO_EDITOR"
      ];
    };
  in
    lib.mkMerge [
      implementationConfig
      myConfig
    ];
}
