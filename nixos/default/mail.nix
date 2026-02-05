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
  options.services.postfix = {
    sendDirect = lib.mkEnableOption "sending emails to remote SMTP servers directly";
    sendViaMythicBeasts = lib.mkEnableOption "sending emails via the Mythic Beasts SMTP servers";
  };

  config = lib.mkMerge [
    {
      warnings = lib.optional ((!cfg.sendDirect) && (!cfg.sendViaMythicBeasts)) ''
        Neither services.postfix.sendDirect nor
        services.postfix.sendViaMythicBeasts are set.  You want one or the
        other to be able to send emails from this system.
      '';

      assertions = [
        {
          assertion = !(cfg.sendDirect && cfg.sendViaMythicBeasts);
          message = ''
            services.postfix.sendDirect and
            services.postfix.sendViaMythicBeasts conflict.  You must only
            enable one or the other.
          '';
        }
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

    (lib.mkIf cfg.sendViaMythicBeasts {
      sops = {
        secrets.smtp-auth = { };
        templates.smtp-auth = {
          content = "[smtp-auth.mythic-beasts.com]:587 ${config.sops.placeholder.smtp-auth}";
          restartUnits = [ "postfix-setup.service" ];
        };
      };

      services.postfix = {
        mapFiles.sasl_passwd = config.sops.templates.smtp-auth.path;

        settings.main = {
          smtp_sasl_auth_enable = true;
          smtp_sasl_password_maps = "hash:/var/lib/postfix/conf/sasl_passwd";
          smtp_sasl_tls_security_options = "noanonymous";
          smtp_tls_security_level = "secure";
          smtp_tls_mandatory_ciphers = "high";
          smtp_tls_mandatory_protocols = ">=TLSv1.3";
          relayhost = [ "[smtp-auth.mythic-beasts.com]:587" ];
        };
      };
    })
  ];
}
