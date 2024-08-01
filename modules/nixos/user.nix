{
  config,
  lib,
  ...
}: let
  # If this is a WSL system, use the Windows username; in theory that's not
  # necessary, but in practice a bunch of things need extra work without this
  # (e.g. the UIDs get confused, and you can't launch GUI applications as a
  # result).
  #
  # TODO Remove duplication with modules/nixos/pd/default.nix
  username =
    if config.system.isWsl
    then config.wsl.defaultUser
    else "adam";

  passwordConfig =
    if builtins.pathExists ../../secrets/adam
    then {hashedPasswordFile = builtins.toString ../../secrets/adam;}
    else if builtins.pathExists ../../passwords/adam
    then {hashedPasswordFile = builtins.toString ../../passwords/adam;}
    else {};
in {
  # Always want fixed users.
  users.mutableUsers = false;

  # Set up my user account.
  users.users."${username}" =
    {
      isNormalUser = true;
      description = "Adam Dinwoodie";
      extraGroups = ["wheel"];
      linger = true;
    }
    // passwordConfig;
}
