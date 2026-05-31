{ config, pdnix, ... }:
let
  fqdn = config.networking.fqdn;

  isoPackage = pdnix.packages.x86_64-linux.default;
in
{
  services.nginx = {
    enable = true;
    virtualHosts."${fqdn}".locations."= /${isoPackage.isoName}" = {
      root = "${isoPackage}/iso";
      extraConfig = ''
        auth_basic off;
      '';
    };
  };
}
