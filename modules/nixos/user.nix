{
  config,
  lib,
  ...
}: {
  options.users.me = lib.mkOption {
    type = lib.types.str;
    description = "My username";
    apply = username: let
      normalUsers =
        builtins.filter (user: user.isNormalUser)
        (builtins.attrValues config.users.users);
      normalUserNames = map (user: user.name) normalUsers;
    in
      username;
  };

  config.assertions = let
    normalUsers =
      builtins.filter (user: user.isNormalUser)
      (builtins.attrValues config.users.users);
    normalUserNames = map (user: user.name) normalUsers;
  in [
    {
      assertion = builtins.elem config.users.me normalUserNames;
      message = ''
        `users.me` set to ${config.users.me}, which doesn't appear in
        `users.users`.
      '';
    }
  ];
}
