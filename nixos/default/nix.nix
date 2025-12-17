{ config, lib, ... }:
{
  options.nix.daemonEnvironmentFromSops =
    lib.mkEnableOption "getting the Nix daemon environment from SOPS."
    // {
      default = true;
    };

  config = lib.mkIf config.nix.daemonEnvironmentFromSops {
    sops.secrets.nix-daemon-environment = { };
    systemd.services.nix-daemon.serviceConfig.EnvironmentFile =
      config.sops.secrets.nix-daemon-environment.path;
  };
}
