# Open the Syncthing ports if the user account has Syncthing configured.
{
  config,
  lib,
  self,
  ...
}:
let
  homeConfig = self.homeConfigurations."${config.users.me}@${config.networking.hostName}".config or (lib.warn "No available home configuration" { });
in
{
  networking.firewall = lib.mkIf (homeConfig.services.syncthing.enable or false) {
    allowedTCPPorts = [ 22000 ];
    allowedUDPPorts = [
      21027
      22000
    ];
  };
}
