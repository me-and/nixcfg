{
  inputs,
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [ inputs.wsl.nixosModules.default ];

  wsl.enable = true;
  wsl.defaultUser = lib.mkDefault config.users.me;

  # Override config from the regular config file.
  boot.loader = lib.mkForce {
    systemd-boot.enable = false;
    efi.canTouchEfiVariables = false;
  };

  # Don't want mDNS services, as I can get them from Windows.
  services.avahi.enable = lib.mkForce false;

  # Don't want to connect over SSH, there's no need for that.
  services.openssh.enable = false;

  environment.systemPackages = with pkgs; [
    putty # For psusan
    mypkgs.start # For start
    wslu # For wslview
  ];

  # I've seen problems with Nix store corruption on WSL, and these seem to
  # help.
  nix.settings = {
    fsync-metadata = true;
    fsync-store-paths = true;
  };

  # OS should be looking after the clock.
  services.timesyncd.enable = false;
}
