{
  config,
  lib,
  pkgs,
  ...
}:
let
  fqdn = config.networking.fqdn;
  hasFqdn = (builtins.tryEval fqdn).success;

  certCfg = config.security.acme.certs;
in
{
  services.postfix = {
    # Always want to at least be able to deliver mail locally.
    enable = true;
    settings.main.myhostname = lib.mkIf hasFqdn (lib.mkDefault fqdn);

    # Accept email from the local system and nowhere else.
    settings.main.inet_interfaces = "loopback-only";

    # If we have them, use TLS certificates.  This really ought to depend on
    # settings.main.myhostname, but I haven't found a way to make that work
    # without infinite recursion errors, and I decided I didn't care enough at
    # the time to debug further...
    settings.main.smtp_tls_chain_files = lib.mkIf (hasFqdn && certCfg ? "${fqdn}") [
      "${certCfg."${fqdn}".directory}/full.pem"
    ];
  };

  # Always want to be able to use `mail` to send emails.
  environment.systemPackages = [ pkgs.mailutils ];
  environment.etc = lib.mkIf hasFqdn {
    "mailutils.conf".text = ''
      address {
        email-domain ${fqdn};
      };
    '';
  };
}
