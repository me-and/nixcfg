# Open the Syncthing ports if the user account has Syncthing configured.
{
  config,
  lib,
  homeConfig,
  ...
}:
{
  networking.firewall = lib.mkIf homeConfig.services.syncthing.enable {
    allowedTCPPorts = [ 22000 ];
    allowedUDPPorts = [
      21027
      22000
    ];
  };
}
