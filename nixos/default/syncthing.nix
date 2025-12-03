# Open the Syncthing ports if the user account has Syncthing configured.
{
  config,
  lib,
  self,
  ...
}:
let
  homeConfig = self.homeConfigurations."${config.users.me}@${config.networking.hostName}".config;
in
{
  networking.firewall = lib.mkIf homeConfig.services.syncthing.enable {
    allowedTCPPorts = [ 22000 ];
    allowedUDPPorts = [
      21027
      22000
    ];
  };
}
