{ nixos-hardware, ... }:
{
  imports = [ nixos-hardware.nixosModules.dell-latitude-7430 ];

  system.stateVersion = "25.11";

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.domain = "dinwoodie.org";
  networking.wireless.enable = true;

  # TODO Set up certificates to enable this.
  networking.pd.vpn = false;
  networking.pd.gonzo = false;

  programs.mosh.enable = true;

  # TODO set up keys to enable this.
  nix.nixBuildDotNet.substituter.enable = false;

  services.postfix.sendDirect = true;

  nix.nhgc = {
    trigger.freePercent = 15;
    target.freePercent = 25;
  };
}
