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
      wslu # For wslview
    ];

    # I've seen problems with Nix store corruption on WSL.  Hopefully this will
    # help...
    #
    # Need Nix 2.25 or higher to have the fsync-store-paths option available,
    # which also means the NixOS config can't cope with that argument yet.
    nix.package =
      if lib.versionAtLeast pkgs.nix.version "2.25"
      then lib.warn "Unnecessary nix package version handling in ${toString ./.}/wsl.nix" pkgs.nix
      else pkgs.nixVersions.nix_2_25;
    nix.settings.fsync-metadata = true;
    nix.extraOptions = "fsync-store-paths = true";

    # OS should look after the clock.  Hopefully.
    services.timesyncd.enable = false;
  };
}
