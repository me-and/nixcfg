{
  lib,
  pkgs,
  ...
}: {
  imports = [
    <nixos-hardware/framework/16-inch/7040-amd>
    ./hardware-configuration.nix
    ../common
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
  hardware.bluetooth.enable = true;
  services.hardware.bolt.enable = true;
  services.colord.enable = true;
  services.samba.enable = true;

  # This setting seems to be necessary to have both the speakers and mics work
  # on my Bluetooth headsets.
  # https://atish3604.medium.com/solved-bluetooth-headset-mic-not-working-detected-in-ubuntu-20-04-86a5236444d0
  services.pipewire.pulse.enable = true;

  services.postfix = {
    enable = true;
    relayHost = "smtp.tastycake.net";
    relayPort = 587;
  };

  programs.steam.enable = true;

  # Use Nautilus, the Gnome file manager as well as the KDE one, as I prefer
  # the search interface for it.  Also enable the indexing tools that it uses.
  environment.systemPackages = [pkgs.gnome.nautilus];
  services.gnome.tracker.enable = true;
  services.gnome.tracker-miners.enable = true;

  programs.kdeconnect.enable = true;

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

  hardware.frameworkBluetoothWorkaround = true;
}
