{
  config,
  lib,
  pkgs,
  ...
}: let
  fqdn = config.networking.fqdn;
  hasFqdn = (builtins.tryEval fqdn).success;

  cfg = config.services.postfix;

  # It's still a default at relatively low priority, but it's a bit more pushy
  # than a regular default, so it'll override something else defined with
  # `lib.mkDefault`.
  mkPushyDefault = lib.mkOverride ((lib.mkDefault null).priority - 5);
in {
  options.services.postfix = {
    relayAuthFile = lib.mkOption {
      description = ''
        Path to the file containing with authentication information for
        connecting to SMTP servers.  This file should be in a format similar to
        the below:

            [smtp.gmail.com]:587 user@gmail.com:password
            [smtp.mail.yahoo.com]:465 user@yahoo.com:password
      '';
      type = lib.types.nullOr lib.types.path;
      default = null;
    };

    secureAuth = lib.mkOption {
      description = ''
        Whether to set up SMTP authentication to use secure connections.  By
        default, this will be enabled if there is a relay authentication file,
        as you want to be sure the connection to the relay is secure, and
        disabled otherwise, as either you're not connecting anywhere remotely
        or you're sending mail directly so can't rely on any particular server
        supporting TLS.
      '';
      type = lib.types.bool;
      default = cfg.relayAuthFile != null;
    };
  };

  config = let
    # Stuff where I'm surprised the default isn't already set, so I want to set
    # it.
    defaultConfig = {
      services.postfix = {
        # Use the system domain on outgoing emails.
        hostname = lib.mkIf hasFqdn (lib.mkDefault fqdn);

        # Accept email from the local system, and nowhere else.
        config.inet_interfaces = lib.mkDefault "loopback-only";
      };
    };

    # Stuff for configuring authentication to a relay server.  Most of this
    # could be configured using services.postfix.mapFiles, but that would put
    # secrets in the Nix store, which I don't want.
    relayAuthConfig = lib.mkIf (cfg.enable && (cfg.relayAuthFile != null)) {
      services.postfix.config = {
        smtp_sasl_auth_enable = true;
        smtp_sasl_password_maps = "hash:/etc/postfix/sasl_passwd";
      };

      systemd.services.postfix-configure-auth = {
        description = "Postfix SMTP authentication configuration";
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = pkgs.writeCheckedShellScript {
            name = "postfix-configure-auth";
            purePath = true;
            runtimeInputs = [pkgs.coreutils];
            text = let
              authFilePath = builtins.toString cfg.relayAuthFile;
            in ''
              umask 0027
              mkdir -p /etc/postfix
              cp \
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

    secureAuthConfig = lib.mkIf (cfg.enable && cfg.secureAuth) {
      services.postfix.config = {
        smtp_use_tls = mkPushyDefault true;
        smtp_sasl_tls_security_options = mkPushyDefault "noanonymous";
        smtp_tls_security_level = mkPushyDefault "secure";
        smtp_tls_mandatory_ciphers = mkPushyDefault "high";
        smtp_tls_mandatory_protocols = mkPushyDefault ">=TLSv1.3";
      };
    };
  in
    lib.mkMerge [
      defaultConfig
      relayAuthConfig
      secureAuthConfig
    ];
}
