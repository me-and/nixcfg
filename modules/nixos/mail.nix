{
  config,
  lib,
  pkgs,
  ...
}: let
  tryFqdn = builtins.tryEval config.networking.fqdn;
  fqdn = tryFqdn.value;
  hasFqdn = tryFqdn.success;

  # Enable postfix to set up sending emails externally.  Probably want to
  # configure a .forward file in your home directory to get emails sent locally
  # to be forwarded externally, too.
  postfixCommonConfig = lib.mkIf config.services.postfix.enable {
    services.postfix = {
      # Forward emails sent to root to me.
      rootAlias = config.users.me;

      # Set the domain on outgoing emails sent through postfix's sendmail to be
      # the FQDN of this system.  Slightly surprised this isn't the default.
      hostname = fqdn;

      # Send outgoing email from this system, don't accept mail from anywhere
      # else.  Slightly surprised there isn't a simpler toggle for this...
      config.inet_interfaces = "loopback-only";
    };
  };

  # No relay server?  Configure postfix for sending mails directly to SMTP
  # servers.  This will almost certainly require the local system to have a
  # fixed IP address and a bunch of DNS setup.
  postfixLocalSendConfig = lib.mkIf (config.services.postfix.relayHost == "") {
    # Create certificates for the server.
    security.acme.certs."${fqdn}" = {};

    services.postfix = let
      certDir = config.security.acme.certs."${fqdn}".directory;
    in {
      sslKey = "${certDir}/key.pem";
      sslCert = "${certDir}/cert.pem";
    };
  };

  # No fixed IP address? Configure postfix for sending mails through an
  # authenticated SMTP relay.
  postfixRelaySendConfig = lib.mkIf (config.services.postfix.relayHost != "") {
    services.postfix.config = {
      smtp_sasl_auth_enable = true;
      smtp_sasl_password_maps = "hash:/etc/postfix/sasl_passwd";
      smtp_use_tls = true;
      smtp_sasl_tls_security_options = "noanonymous";
      smtp_tls_security_level = "secure";
      smtp_tls_mandatory_ciphers = "high";
      smtp_tls_mandatory_protocols = ">=TLSv1.3";
    };

    # Set up the SMTP passwords.  I don't want to use, say,
    # services.postfix.mapFiles for this, because that inherently puts the
    # files in the Nix store.
    systemd.services.postfix-configure-smtp = {
      description = "Postfix SMTP authentication configuration";
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = pkgs.writeCheckedShellScript {
          name = "postfix-configure-smtp";
          purePath = true;
          runtimeInputs = [pkgs.coreutils];
          text = let
            secretsPath = builtins.toString ../../secrets;
          in ''
            umask 0027
            mkdir -p /etc/postfix
            cp ${lib.strings.escapeShellArg secretsPath}/sasl_passwd /etc/postfix/sasl_passwd
            ${pkgs.postfix}/bin/postmap /etc/postfix/sasl_passwd
          '';
        };
      };
      requiredBy = ["postfix.service" "postfix-setup.service"];
      before = ["postfix.service"];
      after = ["postfix-setup.service"];

      # postfix-setup.service will wipe the postfix directory, so the
      # postfix-configure-smtp service needs to be restarted if postfix-setup
      # is restarted.
      bindsTo = ["postfix-setup.service"];
    };

    systemd.services.postfix.restartTriggers = [
      config.systemd.units."postfix-configure-smtp.service".unit
    ];
  };

  # Set up the GNU mail package, for sending and accessing email using the
  # `mail` command.  If we have an FQDN, use that on outgoing emails it sends,
  # too.
  mailConfig = {
    environment.systemPackages = [pkgs.mailutils];
    environment.etc = lib.mkIf hasFqdn {
      "mailutils.conf".text = ''
        address {
          email-domain ${fqdn};
        };
      '';
    };
  };
in {
  config = lib.mkMerge [
    postfixCommonConfig
    postfixLocalSendConfig
    postfixRelaySendConfig
    mailConfig
  ];
}
