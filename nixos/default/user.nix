{
  config,
  lib,
  ...
}:
let
  cfg = config.users;
in
{
  options.users.me = lib.mkOption {
    type = lib.types.str;
    description = "My username";
    apply =
      username:
      let
        normalUsers = builtins.filter (user: user.isNormalUser) (builtins.attrValues config.users.users);
        normalUserNames = map (user: user.name) normalUsers;
      in
      username;
  };

  config = {
    # Always want fixed users.
    users.mutableUsers = false;

    # Set up my user account.
    users.users."${cfg.me}" = {
      isNormalUser = true;
      description = "Adam Dinwoodie";
      extraGroups = [
        "wheel"
        "cdrom"
      ];
      linger = true;
    };

    # Mail for root should come to me.
    services.postfix.rootAlias = cfg.me;
  };
}
