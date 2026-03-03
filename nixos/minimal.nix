{ config, ... }:
{
  users.users."${config.users.me}".hashedPassword = "";
  users.users.root.hashedPassword = "";
  services.sudo.wheelNeedsPassword = false;

  nix.gc.store.enable = false;
  nix.nixBuildDotNet.substituter.enable = false;
  nix.githubTokenFromSops = false;
}
