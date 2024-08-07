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
  postfixConfig = lib.mkIf config.services.postfix.enable {
    # Create certificates for the server.
    security.acme.certs."${fqdn}" = {};

    services.postfix = let
      certDir = config.security.acme.certs."${fqdn}".directory;
    in {
      sslKey = "${certDir}/key.pem";
      sslCert = "${certDir}/cert.pem";

      # Forward emails sent to root to me.
      rootAlias = config.users.me;

      # Set the domain on outgoing emails sent through postfix's sendmail to be
      # the FQDN of this system.  Slightly surprised this isn't the default.
      hostname = fqdn;

      # Send outgoing email from this system, don't accept mail from anywhere
      # else.  Slightly surprised there isn't a simpler toggle for this...
      extraConfig = ''
        inet_interfaces = loopback-only
      '';
    };
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
in
  lib.mkMerge [
    postfixConfig
    mailConfig
  ]
