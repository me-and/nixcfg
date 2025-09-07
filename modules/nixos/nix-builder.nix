{
  config,
  lib,
  ...
}: let
  cfg = config.nix.localBuildServer;
in {
  options.nix.localBuildServer = {
    enable = lib.mkEnableOption "using the local system as a build machine for other systems";
    buildUser = lib.mkOption {
      type = lib.types.str;
      default = "nixremote";
      description = "Username for the SSH account used for remote builds.";
    };
    buildUserGroup = lib.mkOption {
      type = lib.types.str;
      default = cfg.buildUser;
      description = "Group name for the SSH account used for remote builds";
    };
    permittedSshKeys = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      description = "SSH keys permitted to log in as the build user to perform builds";
      default = [];
    };
  };

  config = lib.mkIf cfg.enable {
    users.users."${cfg.buildUser}" = {
      isNormalUser = true;
      description = "Remote nix build account";
      openssh.authorizedKeys.keys =
        map (key: "command=\"/run/current-system/sw/bin/nix-store --serve --write\" ${key}") cfg.permittedSshKeys;
      group = cfg.buildUserGroup;
    };
    users.groups."${cfg.buildUserGroup}" = {};
    nix.settings.trusted-users = [cfg.buildUser];

    nix.sshServe = {
      enable = true;
      write = true;
      trusted = true;
      keys = cfg.permittedSshKeys;
    };
  };
}
