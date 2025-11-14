{ config, sops-nix, ... }:
{
  imports = [ sops-nix.homeModules.sops ];

  sops.age.sshKeyPaths = [ "${config.home.homeDirectory}/.ssh/id_ed25519" ];
}
