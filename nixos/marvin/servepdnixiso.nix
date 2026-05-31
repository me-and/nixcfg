{
  config,
  lib,
  pdnix,
  ...
}:
let
  fqdn = config.networking.fqdn;

  isoPackage = pdnix.packages.x86_64-linux.default;
in
# Avoid build errors where the ISO image isn't available because I'm using a
# placeholder flake.
if pdnix ? packages then
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
else
  lib.warn "not serving the PD ISO file thanks to the placeholder flake" { }
