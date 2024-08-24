{
  config,
  lib,
  ...
}: let
  cfg = config.users;
in {
  # Always want fixed users.
  users.mutableUsers = false;

  # If this is a WSL system, use the Windows username; in theory that's not
  # necessary, but in practice a bunch of things need extra work without this
  # (e.g. the UIDs get confused, and you can't launch GUI applications as a
  # result).
  users.me =
    if config.system.isWsl
    then config.wsl.defaultUser
    else "adam";

  # Set up my user account.
  users.users."${cfg.me}" = {
    isNormalUser = true;
    description = "Adam Dinwoodie";
    extraGroups = ["wheel"];
    linger = true;
    hashedPasswordFile = builtins.toString ../../secrets/adam;
  };

  # Mail for root should come to me.
  services.postfix.rootAlias = cfg.me;
}
