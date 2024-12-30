{pkgs, ...}: {
  imports = [
    ../common
    ./hardware-configuration.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # TODO Work out why this doesn't seem to be having any effect.
  virtualisation.hypervGuest.videoMode = "1920x1080";

  networking.hostName = "saw";
  networking.domain = "dinwoodie.org";

  networking.networkmanager.enable = true;

  networking.accessPD = true;

  services.xserver.enable = true;
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;
  services.samba.enable = true;

  services.postfix = {
    enable = true;
    relayHost = "smtp.tastycake.net";
    relayPort = 587;
  };

  system.stateVersion = "24.05";

  nix.nixBuildDotNet = {
    enableSubstituter = true;
    sshKeyPath = "/etc/nixos/secrets/nixbuild-key";
  };

  nix.settings = {
    max-jobs = 4;
    cores = 10;
  };

  # Allow working with all the LVM features I sometimes use.
  boot.initrd.kernelModules = ["dm-snapshot" "dm-raid" "dm-mirror"];
}
