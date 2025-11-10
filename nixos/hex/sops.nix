{ config, ... }:
{
  users.users = {
    "${config.users.me}".hashedPasswordFile = "/etc/nixos/secrets/adam";
    root.hashedPasswordFile = "/etc/nixos/secrets/root";
  };
}
