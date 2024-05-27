{ config, lib, pkgs, ... }:
{
  config = {
    wsl.enable = true;
    wsl.defaultUser = "adam";

    # Override config from the regular config file.
    boot.loader = lib.mkForce {
      systemd-boot.enable = false;
      efi.canTouchEfiVariables = false;
    };

    # Don't want printing, sound or mDNS services, as I can get them from
    # Windows.
    services.printing.enable = lib.mkForce false;
    sound.enable = lib.mkForce false;
    hardware.pulseaudio.enable = lib.mkForce false;
    services.avahi.enable = lib.mkForce false;
    services.avahi.nssmdns = lib.mkForce false;

    # Don't want to connect over SSH.
    services.openssh.enable = lib.mkForce false;

    environment.systemPackages = with pkgs; [
      putty  # For psusan
      wslu  # For wslview
    ];

    nix.channels.nixos-wsl = https://github.com/nix-community/NixOS-WSL/archive/refs/heads/main.tar.gz;
  };
}

# TODO Better modeline and/or better Vim plugins for Nix config files.
# vim: et ts=2 sw=2 autoindent
