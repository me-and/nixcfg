{
  lib,
  config,
  ...
}:
let
  cfg = config.services.taskserver;
in
{
  services.taskserver = {
    enable = true;

    # I want to connect to this server from other systems.
    openFirewall = true;
    listenHost = "0.0.0.0";
    fqdn = "taskwarrior.dinwoodie.org";
    listenPort = 50340;

    # I already have a CA certificate for clients to connect.
    pki.manual =
      let
        dir = config.security.acme.certs."${cfg.fqdn}".directory;
      in
      {
        ca.cert = ./ca.cert.pem;
        server.cert = "${dir}/fullchain.pem";
        server.key = "${dir}/key.pem";
      };

    organisations.adam.users = [ "adam" ];
    organisations.adam.groups = [ "users" ];
  };

  security.acme.certs."${cfg.fqdn}" = {
    group = cfg.group;
  };

  systemd.services.taskserver = {
    wants = [ "acme-${cfg.fqdn}.service" ];
    after = [ "acme-${cfg.fqdn}.service" ];
  };
}
