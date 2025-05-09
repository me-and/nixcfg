{pkgs, ...}: {
  imports = [
    ./hardware-configuration.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "saw";
  networking.domain = "dinwoodie.org";

  networking.networkmanager.enable = true;

  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;
  services.samba.enable = true;

  services.postfix = {
    enable = true;
    relayHost = "smtp.tastycake.net";
    relayPort = 587;
  };

  system.stateVersion = "24.11";

  nix.settings = {
    max-jobs = 4;
    cores = 10;
  };

  # Allow working with all the LVM features I sometimes use.
  boot.initrd.kernelModules = ["dm-snapshot" "dm-raid" "dm-mirror"];
}
