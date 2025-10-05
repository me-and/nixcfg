{
  config,
  lib,
  pkgs,
  ...
}: let
in {
  imports = [(lib.mkRenamedOptionModule ["system" "isWsl"] ["wsl" "enable"])];

  config = lib.mkIf config.wsl.enable {
    # Override config from the regular config file.
    boot.loader = lib.mkForce {
      systemd-boot.enable = false;
      efi.canTouchEfiVariables = false;
    };

    # Don't want mDNS services, as I can get them from Windows.
    services.avahi.enable = lib.mkForce false;

    # Don't want to connect over SSH; there's no need for that.
    services.openssh.enable = false;

    environment.systemPackages = with pkgs; [
      putty # For psusan
      mypkgs.start # For start
      wslu # For wslview
    ];

    # I've seen problems with Nix store corruption on WSL.  Hopefully this will
    # help...
    nix.settings.fsync-metadata = true;
    nix.settings.fsync-store-paths = true;

    # OS should look after the clock.  Hopefully.
    services.timesyncd.enable = false;
  };
}
