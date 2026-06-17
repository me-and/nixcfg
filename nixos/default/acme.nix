{ config, lib, ... }:
lib.mkIf (config.security.acme.certs != { }) {
  sops.secrets.mythic-beasts = { };
  security.acme = {
    acceptTerms = true;
    defaults = {
      dnsProvider = "mythicbeasts";
      # Use Mythic Beasts' own DNS servers.  This seems to make certificate
      # renewal much more reliable.
      # https://www.mythic-beasts.com/support/domains/nameservers
      dnsResolver = builtins.concatStringsSep "," [
        "45.33.127.156:53"
        "93.93.128.67:53"
        "[2600:3c00:e000:19::1]:53"
        "[2a00:1098:0:80:1000::10]:53"
      ];
      environmentFile = config.sops.secrets.mythic-beasts.path;
    };
  };
}
