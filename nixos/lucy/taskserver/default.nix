{
  lib,
  config,
  ...
}: let
  cfg = config.services.taskserver;
in {
  services.taskserver = {
    enable = true;

    # I want to connect to this server from other systems.
    openFirewall = true;
    listenHost = "0.0.0.0";
    fqdn = "taskwarrior.dinwoodie.org";
    listenPort = 50340;

    # I already have a CA certificate for clients to connect.
    pki.manual = let
      dir = "/var/lib/acme/${cfg.fqdn}";
    in {
      ca.cert = ./ca.cert.pem;
      server.cert = "${dir}/fullchain.pem";
      server.key = "${dir}/key.pem";
    };

    organisations.adam.users = ["adam"];
    organisations.adam.groups = ["users"];
  };

  # https://github.com/NixOS/nixpkgs/pull/369509
  systemd.services.taskserver-init.preStart = lib.mkForce "";
  systemd.tmpfiles.rules = [
    "d ${cfg.dataDir} 0770 ${cfg.user} ${cfg.group}"
    "z ${cfg.dataDir} 0770 ${cfg.user} ${cfg.group}"
  ];

  security.acme.certs."${cfg.fqdn}" = {
    group = cfg.group;
  };
}
