{
  config,
  pkgs,
  flake,
  ...
}: {
  imports =
    [
      flake.nixos-hardware.nixosModules.raspberry-pi-4
    ]
    ++ builtins.attrValues (flake.self.lib.dirfiles {
      dir = ./.;
      excludes = ["configuration.nix"];
    });

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
  boot.initrd.kernelModules = ["dm-snapshot" "dm-raid" "dm-mirror" "dm-cache" "dm-cache-smq"];

  system.stateVersion = "24.11";
  networking.domain = "dinwoodie.org";

  programs.mosh = {
    enable = true;
    portRange = {
      from = 60000;
      to = 60019;
    };
  };

  services.openssh.ports = [22 44035];

  # TODO This isn't working; can I fix it?
  systemd.watchdog = {
    runtimeTime = "15s";
    rebootTime = "5m";
  };

  networking.pd.vpn = true;
  networking.pd.gonzo = true;

  fileSystems."/home/adam/.cache/mail".options = ["noexec"];
  services.snapper.configs.mail = {
    SUBVOLUME = "/home/adam/.cache/mail";
    ALLOW_USERS = [config.users.me];
    SYNC_ACL = true;
    BACKGROUND_COMPARISON = true;
    TIMELINE_CREATE = true;
    TIMELINE_CLEANUP = true;
    EMPTY_PRE_POST_CLEANUP = true;
  };

  services.beesd.filesystems.mail = {
    hashTableSizeMB = 512;
    spec = "UUID=3c029ca6-21be-43a2-b147-25368bc98336";
  };

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

  nix.nhgc.minimumFreeSpace = 1024 * 1024 * 1024 * 20; # 20GB
}
