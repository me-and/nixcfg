{
  config,
  lib,
  ...
}: let
  cfg = config.services.jellyfin;
in {
  options.services.jellyfin = {
    fqdn = lib.mkOption {
      description = "FQDN on which to provide the Jellfin server";
      example = "example.org";
      type = lib.types.str;
    };
  };

  config = lib.mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = [80 443];
    services.nginx = {
      enable = true;
      # TODO how do I make these settings part of the virtual host settings?
      # Do I even want to do that?
      recommendedProxySettings = true;
      recommendedTlsSettings = true;
      virtualHosts."${cfg.fqdn}" = {
        enableACME = true;
        forceSSL = true;
        locations."/".proxyPass = "http://127.0.0.1:8096";
      };
    };
  };
}
