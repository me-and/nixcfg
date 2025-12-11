{
  config,
  lib,
  mylib,
  options,
  ...
}:
let
  cfg = config.users;

  hasHashedPassword = cfg.users."${cfg.me}".hashedPassword != null;
in
{
  options.users.me = lib.mkOption {
    type = lib.types.str;
    description = "My username";
  };

  config = {
    warnings = lib.optional hasHashedPassword ''
      Hashed password set for ${cfg.me}, so no password will be used from SOPS.
    '';

    # Always want fixed users.
    users.mutableUsers = false;

    # Set up my user account.
    sops.secrets = lib.mkIf (!hasHashedPassword) {
      "users/${cfg.me}" = {
        name = cfg.me;
        neededForUsers = true;
      };
    };

    users.users."${cfg.me}" = {
      isNormalUser = true;
      description = "Adam Dinwoodie";
      hashedPasswordFile = lib.mkIf (!hasHashedPassword) config.sops.secrets."users/${cfg.me}".path;
      extraGroups = [
        "wheel"
        "cdrom"
      ];
      linger = true;
    };

    # Mail for root should come to me.
    services.postfix.rootAlias = cfg.me;

    users.groups = {
      docker = lib.mkIf config.virtualisation.docker.enable {
        members = [ cfg.me ];
      };
    };
  };
}
