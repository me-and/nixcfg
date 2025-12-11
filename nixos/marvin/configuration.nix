{ lib, nixos-hardware, ... }:
{
  imports = [ nixos-hardware.nixosModules.dell-latitude-7430 ];

  system.stateVersion = "25.11";

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.domain = "dinwoodie.org";

  # TODO Set up certificates to enable this.
  networking.pd.vpn = false;
  networking.pd.gonzo = false;

  # TODO Set up real passwords in sops.
  users.users.adam.hashedPassword = "doot";
  users.users.root.hashedPassword = "doot";

  # TODO Stop disabling the environment.
  nix.daemonEnvironmentFromSops = false;

  programs.mosh = {
    enable = true;
    portRange = {
      from = 60040;
      to = 60059;
    };
  };

  services.openssh.ports = [ 22 52906 ];

  # TODO set up keys to enable this.
  nix.nixBuildDotNet.substituter.enable = false;

  nix.nhgc = {
    trigger.freePercent = 15;
    target.freePercent = 25;
  };
}
