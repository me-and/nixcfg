{
  config,
  lib,
  options,
  pkgs,
  wsl,
  ...
}:
{
  imports = [ wsl.nixosModules.default ];

  wsl.enable = true;
  wsl.defaultUser = lib.mkDefault config.users.me;

  # Override config from the regular config file.
  boot.loader = lib.mkForce {
    systemd-boot.enable = false;
    efi.canTouchEfiVariables = false;
  };

  # Don't want mDNS services, as I can get them from Windows.
  services.avahi.enable = lib.mkForce false;

  # Don't want to connect over SSH, there's no need for that.  Do still want
  # system SSH keys to be generated, though, as they're used for SOPS and the
  # like.
  #
  # TODO Remove the conditional once I've upgraded my config to a version that
  # definitely has this option.
  services.openssh = {
    enable = false;
  }
  // lib.optionalAttrs (options.services.openssh ? generateHostKeys) {
    generateHostKeys = true;
  };

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
