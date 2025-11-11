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
  };

  config = {
    # Always want fixed users.
    users.mutableUsers = false;

    # Set up my user account.
    sops.secrets."users/${cfg.me}" = {
      name = cfg.me;
      neededForUsers = true;
    };

    users.users."${cfg.me}" = {
      isNormalUser = true;
      description = "Adam Dinwoodie";
      hashedPasswordFile = config.sops.secrets."users/${cfg.me}".path;
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
