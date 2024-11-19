{
  config,
  pkgs,
  ...
}: let
  secretsDir = builtins.toString ../../secrets;
in {
  imports = [
    <nixos-hardware/raspberry-pi/4>
    ../common
    ./hardware-configuration.nix
    ./media.nix
  ];

  # https://nixos.wiki/wiki/NixOS_on_ARM/Raspberry_Pi_4
  hardware = {
    raspberry-pi."4".apply-overlays-dtmerge.enable = true;
    deviceTree.enable = true;
    deviceTree.filter = "*rpi-4-*.dtb";
  };

  # Allow working with all LVM features I sometimes use.
  boot.initrd.kernelModules = ["dm-snapshot" "dm-raid" "dm-mirror"];

  # Mild I/O and disk lifetime improvements
  # https://nixos.wiki/wiki/Storage_optimization#Moving_the_store
  #
  # TODO Can I make this common configuration but only for systems where
  # fileSystems."/nix" is already defined elsewhere?
  fileSystems."/nix".options = ["noatime"];

  system.stateVersion = "24.05";
  system.isPi4 = true;
  networking.hostName = "lucy";
  networking.domain = "dinwoodie.org";

  programs.mosh = {
    enable = true;
    portRange = {
      from = 60000;
      to = 60019;
    };
  };

  services.taskserver = {
    enable = true;
    fqdn = "taskwarrior.dinwoodie.org";
    listenPort = 50340;
    generateAcmeCert = true;
  };

  services.openssh.ports = [22 44035];

  systemd.watchdog = {
    runtimeTime = "15s";
    rebootTime = "5m";
  };

  services.nibbleBackup.enable = true;

  #networking.accessPD = true;

  filesystems."/home/adam/.cache/mail".options = ["noexec"];
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

  services.nixBinaryCache = {
    enable = false;

    # Cache is on a separate partition, so no need to use an absolute size
    # limit, and can use a small free space limit as there shouldn't be
    # anything else that would use space on that partition.
    cache.sizeLimit = null;
    cache.minFree = "100m";
    # TODO add resolver config to use the AAISP resolvers, assuming I don't
    # manage to get this working with the default system resolver?
  };

  services.scanToOneDrive = {
    enable = true;
    ftpPasvPortRange = {
      from = 56615;
      to = 56624;
    };
    scannerUser = "ida";
    scannerHashedPasswordFile = "${secretsDir}/ida";
    uploadUser = "rclone";
  };

  services.gnucashFileServer = {
    enable = true;
    rclone.needsTime = true;
    rclone.needsNetwork = true;
    rclone.gnucashDirectory = "onedrive:Documents/Gnucash";
    extraVirtualHostConfig = {
      enableACME = true;
      acmeRoot = null;
    };
    authFilePath = "${secretsDir}/${config.networking.fqdn}-auth";
  };

  nix.nixBuildDotNet = {
    enable = true;
    enableSubstituter = true;
    sshKeyPath = "/etc/nixos/secrets/nixbuild-key";
  };
}
