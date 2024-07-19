{config, ...}: let
  cfg = config.services.taskserver;
in {
  services.taskserver = {
    # I want to connect to this server from other systems.
    openFirewall = true;
    listenHost = "0.0.0.0";
    fqdn = config.networking.fqdn;

    # I have my own key setup already.
    pki.manual = let
      dir = "/var/lib/acme/${cfg.fqdn}";
    in {
      ca.cert = builtins.toString ./ca.cert.pem;
      server.cert = "${dir}/fullchain.pem";
      server.key = "${dir}/key.pem";
    };

    organisations.adam.users = ["adam"];
    organisations.adam.groups = ["users"];
  };
}
