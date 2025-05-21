{
  config,
  lib,
  ...
}: let
  cfg = config.users;
in {
  # Always want fixed users.
  users.mutableUsers = false;

  # Set up my user account.
  users.users."${cfg.me}" = {
    isNormalUser = true;
    description = "Adam Dinwoodie";
    extraGroups = ["wheel" "cdrom"];
    linger = true;
    # TODO How do I check this file exists in a way
    # that's compatible with both the file being in
    # /etc/nixos/secrets (for normal builds) and in
    # /mnt/etc/nixos/secrets (as part of
    # nixos-install, where checking with something
    # like `assert builtins.pathExists` will want to
    # find the file under /mnt, but the code to use
    # the file expects to find it in a chroot and/or
    # after rebooting with the current /mnt now at
    # /).
    hashedPasswordFile = let
      filePath = "/etc/nixos/secrets/adam";
    in
      #assert builtins.pathExists filePath;
      filePath;
  };

  # Mail for root should come to me.
  services.postfix.rootAlias = cfg.me;
}
