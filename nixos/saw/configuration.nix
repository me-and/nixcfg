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

  # Use Nautilus, the Gnome file manager as well as the KDE one, as I prefer
  # the search interface for it.  Also enable the indexing tools that it uses.
  environment.systemPackages = [pkgs.gnome.nautilus];
  services.gnome.tracker.enable = true;
  services.gnome.tracker-miners.enable = true;

  system.stateVersion = "24.05";
}
