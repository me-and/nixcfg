{
  config,
  lib,
  pkgs,
  ...
}: let
  fqdn = config.networking.fqdn;
  hasFqdn = (builtins.tryEval fqdn).success;

  cfg = config.services.postfix;

  commonConfig = {
    # Always waint to at least be able to deliver mail locally.
    services.postfix = {
      enable = true;
      hostname = lib.mkIf hasFqdn (lib.mkDefault fqdn);

      # Accept email from the local system and nowhere else.
      config.inet_interfaces = "loopback-only";
    };

    # Always want to be able to use `mail` to send emails.
    environment.systemPackages = [pkgs.mailutils];
    environment.etc = lib.mkIf hasFqdn {
      "mailutils.conf".text = ''
        address {
          email-domain ${fqdn};
        };
      '';
    };
  };

  # If there's no relay host but we do have an FQDN, we should be able to send
  # mail to remote SMTP servers directly.  Configure that.
  postfixLocalSendConfig =
    lib.mkIf (
      cfg.enable
      && hasFqdn
      && (cfg.relayHost == "")
    ) {
      # Create certificates for the server.
      security.acme.certs."${fqdn}" = {};

      services.postfix = let
        certDir = config.security.acme.certs."${fqdn}".directory;
      in {
        sslKey = "${certDir}/key.pem";
        sslCert = "${certDir}/cert.pem";
      };
    };

  # Stuff for configuring authentication to a relay server.  Most of this could
  # be configured using services.postfix.mapFiles, but that would put secrets
  # in the Nix store, which I don't want.
  postfixRelayConfig = lib.mkIf (cfg.enable && (cfg.relayHost != "")) {
    services.postfix.config = {
      smtp_sasl_auth_enable = true;
      smtp_sasl_password_maps = "hash:/etc/postfix/sasl_passwd";
      smtp_use_tls = true;
      smtp_sasl_tls_security_options = "noanonymous";
      smtp_tls_security_level = "secure";
      smtp_tls_mandatory_ciphers = "high";
      smtp_tls_mandatory_protocols = ">=TLSv1.3";
    };

    systemd.services.postfix-configure-auth = {
      description = "Postfix SMTP authentication configuration";
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = pkgs.mypkgs.writeCheckedShellScript {
          name = "postfix-configure-auth.sh";
          purePath = true;
          runtimeInputs = [pkgs.coreutils];
          text = let
            authFilePath = "/etc/nixos/secrets/sasl_passwd";
          in ''
            umask 0027
            mkdir -p /etc/postfix
            cp -- \
                ${lib.strings.escapeShellArg authFilePath} \
                /etc/postfix/sasl_passwd
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

    # Restart postfix to pick up new authentication data if and when it
    # changes.
    systemd.services.postfix.restartTriggers = [
      config.systemd.units."postfix-configure-auth.service".unit
    ];
  };
in
  lib.mkMerge [
    commonConfig
    postfixLocalSendConfig
    postfixRelayConfig
  ]
