{
  config,
  lib,
  ...
}: let
  # If this is a WSL system, use the Windows username; in theory that's not
  # necessary, but in practice a bunch of things need extra work without this
  # (e.g. the UIDs get confused, and you can't launch GUI applications as a
  # result).
  username =
    if config.system.isWsl
    then config.wsl.defaultUser
    else "adam";

  cfg = config.users.users;
in {
  options.users.me = lib.mkOption {
    type = lib.types.str;
    description = "My username";
    default = username;
  };

  # Always want fixed users.
  users.mutableUsers = false;

  # Set up my user account.
  users.users."${cfg.me}" = {
    isNormalUser = true;
    description = "Adam Dinwoodie";
    extraGroups = ["wheel"];
    linger = true;
    hashedPasswordFile = builtins.toString ../../secrets/adam;
  };
}
