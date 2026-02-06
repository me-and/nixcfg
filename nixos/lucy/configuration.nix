{
  config,
  pkgs,
  nixos-hardware,
  personalCfg,
  ...
}:
{
  imports = [
    nixos-hardware.nixosModules.raspberry-pi-4
    personalCfg.nixosModules.servegnucash
  ];

  boot.initrd.systemd.enable = true;
  boot.initrd.systemd.tpm2.enable = false;
  boot.loader.grub.enable = false;
  boot.loader.generic-extlinux-compatible.enable = true;

  # https://nixos.wiki/wiki/NixOS_on_ARM/Raspberry_Pi_4
  hardware = {
    raspberry-pi."4".apply-overlays-dtmerge.enable = true;
    deviceTree.enable = true;
    deviceTree.filter = "*rpi-4-*.dtb";
  };

  # Allow working with all LVM features I sometimes use.
  boot.initrd.kernelModules = [
    "dm-snapshot"
    "dm-raid"
    "dm-mirror"
    "dm-cache"
    "dm-cache-smq"
  ];

  system.stateVersion = "25.11";
  networking.domain = "dinwoodie.org";

  programs.mosh = {
    enable = true;
    portRange = {
      from = 60000;
      to = 60019;
    };
  };

  services.openssh.ports = [
    22
    44035
  ];

  # TODO This isn't working; can I fix it?
  systemd.settings.Manager = {
    RuntimeWatchdogSec = "15s";
    RebootWatchdogSec = "5m";
  };

  networking.pd.vpn = true;
  networking.pd.gonzo = true;

  # Without this, journalctl shows messages about IPv6 DHCP solicitation every
  # 10s.  AFAICS that *shouldn't* happen because the local version of dhcpcd
  # should have the fix from
  # <https://github.com/NetworkConfiguration/dhcpcd/issues/80>, but it clearly
  # is still happening!
  networking.dhcpcd.IPv6rs = false;

  nix.settings = {
    max-jobs = 2;
    cores = 4;
  };

  nix.nixBuildDotNet.builds = {
    enable = false;
  };

  nix.gc.store = {
    trigger.freePercent = 15;
    target.freePercent = 25;
  };
}
