{ config, ... }:
{
  sops.secrets.nix-cache-key = { };

  services.nix-serve = {
    enable = true;
    openFirewall = true;
    secretKeyFile = config.sops.secrets.nix-cache-key.path;
  };
}
