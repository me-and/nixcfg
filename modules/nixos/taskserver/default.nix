{
  lib,
  config,
  ...
}: let
  cfg = config.services.taskserver;

  commonConfig = {
    services.taskserver = {
      # I want to connect to this server from other systems.
      openFirewall = true;
      listenHost = "0.0.0.0";
      fqdn = lib.mkDefault config.networking.fqdn;

      # I already have a CA certificate for clients to connect.
      pki.manual.ca.cert = builtins.toString ./ca.cert.pem;

      organisations.adam.users = ["adam"];
      organisations.adam.groups = ["users"];
    };
  };

  acmeConfig = lib.mkIf cfg.generateAcmeCert {
    security.acme.certs."${cfg.fqdn}" = {
      group = cfg.group;
    };

    services.taskserver.pki.manual = let
      dir = "/var/lib/acme/${cfg.fqdn}";
    in {
      server.cert = "${dir}/fullchain.pem";
      server.key = "${dir}/key.pem";
    };
  };
in {
  options.services.taskserver.generateAcmeCert = lib.mkEnableOption "generate certificates using ACME";

  config = lib.mkMerge [commonConfig acmeConfig];
}
