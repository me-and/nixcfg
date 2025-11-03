{
  config,
  lib,
  pkgs,
  nixos-hardware,
  personalCfg,
  ...
}:
{
  imports = [
    nixos-hardware.nixosModules.framework-16-7040-amd
    personalCfg.nixosModules.winapps
    personalCfg.nixosModules.nix-builder
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.initrd.kernelModules = [
    # Allow working with all LVM features I sometimes use.
    "dm-snapshot"
    "dm-raid"
    "dm-mirror"
    "dm-cache"
    "dm-cache-smq"

    # Enable SCSI access to CD drives
    # https://discourse.nixos.org/t/makemkv-cant-find-my-usb-blu-ray-drive/23714/4
    "sg"
  ];

  networking.domain = "dinwoodie.org";

  networking.networkmanager.enable = true;
  users.groups.networkmanager.members = [ config.users.me ];

  networking.pd.vpn = true;
  networking.pd.gonzo = true;

  services.xserver.enable = true;
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;
  hardware.bluetooth.enable = true;
  services.hardware.bolt.enable = true;
  services.colord.enable = true;
  services.samba.enable = true;
  services.displayManager.sddm.autoNumlock = true;

  services.printing.enable = true;
  services.printing.drivers = with pkgs; [
    cups-kyocera-3500-4500
    hplip # PD GOD HP printers
    cnijfilter2 # Colour printer in Preston
  ];

  programs.mosh.enable = true;

  services.postfix.sendViaTastycake = true;

  programs.kdeconnect.enable = true;

  system.stateVersion = "24.05";

  nix.settings = {
    max-jobs = 4;
    cores = 8;
  };

  nix.nhgc = {
    target.freePercent = 25;
    trigger.freePercent = 15;
  };

  services.nix-serve.enable = true;
}
