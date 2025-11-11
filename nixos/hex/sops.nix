{ config, lib, ... }:
{
  # TODO Remove this workaround that prevents sops doing anything.
  system.activationScripts.setupSecrets = lib.mkForce { text = ""; };

  # TODO Fix these to use sops rather than force the old handling.
  users.users = {
    "${config.users.me}".hashedPasswordFile = "/etc/nixos/secrets/adam";
    root.hashedPasswordFile = "/etc/nixos/secrets/root";
  };
  systemd.services.nix-daemon.serviceConfig.EnvironmentFile =
    lib.mkForce "-/etc/nixos/secrets/nix-daemon-environment";
  security.acme.defaults.EnvironmentFile = lib.mkForce "/etc/nixos/secrets/mythic-beasts";
}
