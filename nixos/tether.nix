{ lib, ... }:
{
  # May have no internet connection, so don't assume tzupdate will work.
  services.tzupdate.enable = lib.mkForce false;

  # Hopefully improve performance over relatively slow LAN and/or reduce my
  # data consumption over the WAN.
  programs.ssh.extraConfig = ''
    Compression yes
  '';

  # Don't eat my data allowance by uploading and downloading to build machines.
  nix.buildMachines = lib.mkForce [ ];
}
