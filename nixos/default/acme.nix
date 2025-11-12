{ config, lib, ... }:
lib.mkIf (config.security.acme.certs != { }) {
  sops.secrets.mythic-beasts = { };
  security.acme = {
    acceptTerms = true;
    defaults = {
      dnsProvider = "mythicbeasts";
      environmentFile = config.sops.secrets.mythic-beasts.path;
    };
  };
}
