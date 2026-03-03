{ config, ... }:
{
  users.users."${config.users.me}".hashedPassword = "";
  users.users.root.hashedPassword = "!!";

  # User accounts don't have passwords, so don't expect them.
  security.sudo.wheelNeedsPassword = false;

  nix.gc.store.enable = false;
  nix.nixBuildDotNet.substituter.enable = false;
  nix.githubTokenFromSops = false;
}
