{
  config,
  lib,
  pkgs,
  ...
}: let
  fqdn = config.networking.fqdn;
  hasFqdn = (builtins.tryEval fqdn).success;

  cfg = config.programs.mailutils;
in {
  options.programs.mailutils = {
    enable = lib.mkEnableOption "GNU mailutils";
    fqdn = lib.mkOption {
      description = "FQDN to use on outgoing emails.";
      type = lib.types.nullOr lib.types.str;
      default =
        if hasFqdn
        then fqdn
        else null;
      example = "example.org";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [pkgs.mailutils];
    environment.etc = lib.mkIf (cfg.fqdn != null) {
      "mailutils.conf".text = ''
        address {
          email-domain ${cfg.fqdn};
        };
      '';
    };
  };
}
