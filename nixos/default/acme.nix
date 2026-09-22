{ config, lib, ... }:
lib.mkIf (config.security.acme.certs != { }) {
  sops = {
    secrets.mythic-beasts = { };
    # Default propagation timeout of 60 seconds seems to produce intermittent
    # failures.  Increase that significantly to see if it helps...
    templates.acme-mythic-beasts-environment.content = ''
      MYTHICBEASTS_PROPAGATION_TIMEOUT=300
      ${config.sops.placeholder.mythic-beasts}
    '';
  };

  security.acme = {
    acceptTerms = true;
    defaults = {
      dnsProvider = "mythicbeasts";
      # Use Mythic Beasts' own DNS servers.  This seems to make certificate
      # renewal much more reliable.
      # https://www.mythic-beasts.com/support/domains/nameservers
      dnsResolver = builtins.concatStringsSep "," (
        [
          "45.33.127.156:53"
          "93.93.128.67:53"
        ]
        ++ lib.optionals config.networking.enableIPv6 [
          "[2600:3c00:e000:19::1]:53"
          "[2a00:1098:0:80:1000::10]:53"
        ]
      );
      environmentFile = config.sops.templates.acme-mythic-beasts-environment.path;
    };
  };
}
