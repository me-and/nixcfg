{
  config,
  lib,
  pkgs,
  ...
}:
let
  fqdn = config.networking.fqdn;
  hasFqdn = (builtins.tryEval fqdn).success;

  cfg = config.services.postfix;
in
{
  imports = [
    (lib.mkRemovedOptionModule [ "services" "postfix" "sendViaTastycake" ] ''
      Tastycake stopped relaying third-party domain emails, so this configuration
      stopped being useful.
    '')
  ];

  options.services.postfix.sendDirect = lib.mkEnableOption "sending emails to remote SMTP servers directly";

  config = lib.mkMerge [
    {
      warnings = lib.optional (!cfg.sendDirect) ''
        services.postfix.sendDirect is not enabled.  You want this, or to fix
        your config to use an SMTP server, to be able to send emails from this
        system.
      '';

      assertions = [
        {
          assertion = cfg.sendDirect -> hasFqdn;
          message = ''
            services.postfix.sendDirect is configured, but networking.fqdn is
            unset.  The system needs a fully qualified domain name to be able
            to send emails directly.
          '';
        }
      ];

      services.postfix = {
        # Always want to at least be able to deliver mail locally.
        enable = true;
        settings.main.myhostname = lib.mkIf hasFqdn (lib.mkDefault fqdn);

        # Accept email from the local system and nowhere else.
        settings.main.inet_interfaces = "loopback-only";
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

    (lib.mkIf cfg.sendDirect {
      # If we're sending email directly, create certificates so we can
      # authenticate to other SMTP servers.
      security.acme.certs."${fqdn}" = { };

      services.postfix.settings.main.smtp_tls_chain_files = [
        "${config.security.acme.certs."${fqdn}".directory}/full.pem"
      ];
    })
  ];
}
