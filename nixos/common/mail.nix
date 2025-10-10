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
    services.postfix.enable = true;

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

  # If there's a relay configured, I must be authenticating against it, so
  # provide the path for the relay.
  postfixRelayConfig = lib.mkIf (cfg.enable && (cfg.relayHost != "")) {
    services.postfix.relayAuthFile = "/etc/nixos/secrets/sasl_passwd";
  };
in
  lib.mkMerge [
    commonConfig
    postfixLocalSendConfig
    postfixRelayConfig
  ]
