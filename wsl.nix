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

    # TODO Work out why having linger enabled manages to _break_ commands like
    # `systemctl --user status`.  Probably related to
    # https://github.com/microsoft/WSL/issues/10205 although I don't quite
    # understand how.
    #
    # Ideally this would apply the configuration to all users that have
    # isNormalUser, but I can't work out how to do that without infinite
    # recursion :(
    users.users.adam.linger = lib.mkForce false;

    nix.channels.nixos-wsl = https://github.com/nix-community/NixOS-WSL/archive/refs/heads/main.tar.gz;
  };
}

# TODO Better modeline and/or better Vim plugins for Nix config files.
# vim: et ts=2 sw=2 autoindent
