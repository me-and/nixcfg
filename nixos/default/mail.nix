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
    sendViaTastycake = lib.mkEnableOption "sending emails via the Tastycake SMTP servers";
  };

  config = lib.mkMerge [
    {
      warnings = lib.optional ((!cfg.sendDirect) && (!cfg.sendViaTastycake)) ''
        Neither services.postfix.sendDirect nor
        services.postfix.sendViaTastycake is enabled.  You want one or the
        other to be able to send emails from this system.
      '';

      assertions = [
        {
          assertion = !(cfg.sendDirect && cfg.sendViaTastycake);
          message = ''
            services.postfix.sendDirect and services.postfix.sendViaTastycake
            conflict.  You must only enable one or the other.
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

    # Stuff for configuring authentication to a relay server.  Most of this could
    # be configured using services.postfix.mapFiles, but that would put secrets
    # in the Nix store, which I don't want.
    (lib.mkIf cfg.sendViaTastycake {
      services.postfix.settings.main = {
        smtp_sasl_auth_enable = true;
        smtp_sasl_password_maps = "hash:/etc/postfix/sasl_passwd";
        smtp_use_tls = true;
        smtp_sasl_tls_security_options = "noanonymous";
        smtp_tls_security_level = "secure";
        smtp_tls_mandatory_ciphers = "high";
        smtp_tls_mandatory_protocols = ">=TLSv1.3";
        relayhost = [ "smtp.tastycake.net:587" ];
      };

      systemd.services.postfix-configure-auth = {
        description = "Postfix SMTP authentication configuration";
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = pkgs.mypkgs.writeCheckedShellScript {
            name = "postfix-configure-auth.sh";
            purePath = true;
            runtimeInputs = [ pkgs.coreutils ];
            text =
              let
                authFilePath = "/etc/nixos/secrets/sasl_passwd";
              in
              ''
                umask 0027
                mkdir -p /etc/postfix
                cp -- \
                    ${lib.strings.escapeShellArg authFilePath} \
                    /etc/postfix/sasl_passwd
                ${pkgs.postfix}/bin/postmap /etc/postfix/sasl_passwd
              '';
          };
        };
        requiredBy = [
          "postfix.service"
          "postfix-setup.service"
        ];
        before = [ "postfix.service" ];
        after = [ "postfix-setup.service" ];

        # postfix-setup.service will wipe the postfix directory, so the
        # postfix-configure-smtp service needs to be restarted if postfix-setup
        # is restarted.
        bindsTo = [ "postfix-setup.service" ];
      };

      # Restart postfix to pick up new authentication data if and when it
      # changes.
      systemd.services.postfix.restartTriggers = [
        config.systemd.units."postfix-configure-auth.service".unit
      ];
    })
  ];
}
