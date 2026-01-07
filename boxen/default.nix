{ lib, ... }:
{
  options.boxen =
    let
      boxSubmodule =
        { lib, name, ... }:
        {
          options = {
            # Based on NixOS's networking.hostName.
            #
            # TODO: work out how to import NixOS's option configuration for
            # networking.hostName.
            hostName = lib.mkOption {
              description = "System host name";
              type = lib.types.str;
              default = name;
            };

            # TODO: work out how to import NixOS's option configuration for
            # networking.hostName.
            platform = lib.mkOption {
              description = "System platform, used as nixpkgs' hostPlatform.";
              type = with lib.types; either str attrs;
              example = {
                system = "x86_64-linux";
              };
            };

            # TODO: work out how to import NixOS's option configuration for
            # users.users.*.name.
            me.username = lib.mkOption {
              description = "Username for my account";
              type = with lib.types; passwdEntry str;
              default = "adam";
            };

            # TODO: work out how to import NixOS's option configuration for
            # users.users.*.openssh.authorizedKeys.
            me.sshPublicKeys = lib.mkOption {
              description = ''
                A list of OpenSSH public keys corresponding to my account on
                this system.
              '';
              type = with lib.types; listOf singleLineStr;
              default = [ ];
            };
            publicKeys = lib.mkOption {
              description = "A list of the system's OpenSSH public host keys.";
              type = with lib.types; listOf singleLineStr;
              default = [ ];
            };
          };
        };
    in
    lib.mkOption {
      description = "Basic system information";
      type = with lib.types; attrsOf (submodule boxSubmodule);
    };
}
