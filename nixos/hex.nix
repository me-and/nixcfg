{
  imports = [
    <nixos-hardware/framework/16-inch/7040-amd>
    ./hex-hardware.nix
    ./common
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "hex";
  networking.domain = "dinwoodie.org";

  networking.networkmanager.enable = true;

  services.xserver.enable = true;
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;

  services.postfix = {
    enable = true;
    relayHost = "smtp.tastycake.net";
    relayPort = 587;
  };

  nix.settings.substituters = ["http://192.168.1.131"];

  system.stateVersion = "24.05";
}
