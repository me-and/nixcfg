{
  config,
  pkgs,
  nixos-hardware,
  personalCfg,
  ...
}:
{
  imports = [
    nixos-hardware.nixosModules.framework-12-13th-gen-intel
  ];

  # TODO Fix this.
  nix.nixBuildDotNet.substituter.enable = false;

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.domain = "dinwoodie.org";

  networking.networkmanager.enable = true;
  users.groups.networkmanager.members = [ config.users.me ];

  services.xserver.enable = true;
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;
  hardware.bluetooth.enable = true;
  services.hardware.bolt.enable = true;
  services.colord.enable = true;
  services.displayManager.sddm.autoNumlock = true;

  programs.mosh.enable = true;

  system.stateVersion = "25.11";

  nix.settings = {
    max-jobs = 4;
    cores = 8;
  };

  nix.gc.store = {
    target.freePercent = 25;
    trigger.freePercent = 15;
  };
}
