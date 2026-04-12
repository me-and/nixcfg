{ nixos-hardware, personalCfg, ... }:
{
  imports = [
    nixos-hardware.nixosModules.dell-latitude-7430
    personalCfg.nixosModules.nix-builder
    personalCfg.nixosModules.servegnucash
  ];

  system.stateVersion = "25.11";

  # Allow working with all LVM features I sometimes use.
  boot.initrd.kernelModules = [
    "dm-snapshot"
    "dm-raid"
    "dm-mirror"
    "dm-cache"
    "dm-cache-smq"
  ];

  # Ignore the lid closing and opening: this is a laptop being used as a home
  # server, so I want to be able to close the lid and have the system keep
  # running.
  services.logind.settings.Login.HandleLidSwitch = "ignore";

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.domain = "dinwoodie.org";
  networking.wireless.enable = true;

  networking.pd.vpn = true;
  networking.pd.gonzo = true;

  programs.mosh.enable = true;

  nix.settings = {
    max-jobs = 4;
    cores = 6;
  };

  nix.gc.store = {
    trigger.freePercent = 15;
    target.freePercent = 25;
  };
}
