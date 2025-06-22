{
  lib,
  pkgs,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ./pd.nix
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

  networking.hostName = "hex";
  networking.domain = "dinwoodie.org";

  networking.networkmanager.enable = true;

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
    hplip
  ];

  programs.mosh.enable = true;

  services.postfix = {
    enable = true;
    relayHost = "smtp.tastycake.net";
    relayPort = 587;
  };

  programs.steam.enable = true;

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

  system.stateVersion = "24.05";

  hardware.frameworkBluetoothWorkaround = true;

  # Need at least kernel 6.10 for framework-tool to work.  6.10 is out of
  # support, so use 6.12 as a more recent LTS kernel.
  #
  # https://github.com/FrameworkComputer/framework-system/issues/43
  # https://github.com/NixOS/nixpkgs/issues/365709
  boot.kernelPackages =
    if pkgs.linuxPackages.kernelAtLeast "6.10"
    then pkgs.linuxPackages
    else pkgs.linuxKernel.packages.linux_6_12;

  nix.localBuildServer.enable = true;

  nix.settings = {
    max-jobs = 4;
    cores = 8;
  };

  nix.nhgc.minimumFreeSpace = 1024 * 1024 * 1024 * 100; # 100GB

  programs.winapps.enable = true;
}
