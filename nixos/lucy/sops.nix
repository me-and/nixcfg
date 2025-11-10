{ config, ... }:
{
  sops.secrets = {
    "users/adam" = {
      name = "adam";
      neededForUsers = true;
    };
    "users/root" = {
      name = "root";
      neededForUsers = true;
    };
  };

  users.users = {
    "${config.users.me}".hashedPasswordFile = config.sops.secrets."users/adam".path;
    root.hashedPasswordFile = config.sops.secrets."users/root".path;
  };
}
