{lib, ...}: {
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

  networking.accessPD = true;

  services.xserver.enable = true;
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;
  hardware.pulseaudio.enable = true;
  hardware.bluetooth.enable = true;
  services.hardware.bolt.enable = true;
  services.colord.enable = true;
  services.samba.enable = true;
  services.autorandr.enable = true;

  services.postfix = {
    enable = true;
    relayHost = "smtp.tastycake.net";
    relayPort = 587;
  };

  nix.settings.substituters = ["http://192.168.1.131"];

  programs.steam.enable = true;

  # Work around https://github.com/NixOS/nixos-hardware/pull/1151
  environment.etc."libinput/local-overrides.quirks".text = lib.mkForce ''
    [Framework Laptop 16 Keyboard Module]
    MatchName=Framework Laptop 16 Keyboard Module*
    MatchUdevType=keyboard
    MatchDMIModalias=dmi:*svnFramework:pnLaptop16*
    AttrKeyboardIntegration=internal
  '';

  # https://github.com/NixOS/nixos-hardware/pull/1152
  services.udev.extraRules = ''
    KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="32ac", ATTRS{idProduct}=="0012", MODE="0660", GROUP="users", TAG+="uaccess", TAG+="udev-acl"
  '';

  nix.channels = {
    nixos-hardware = "https://github.com/NixOS/nixos-hardware/archive/master.tar.gz";
  };

  system.stateVersion = "24.05";
}
