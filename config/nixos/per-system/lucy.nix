{
  config,
  lib,
  ...
}:
lib.mkIf (config.system.name == "lucy") {
  system.stateVersion = "24.05";
  system.isPi4 = true;
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

  services.nibbleBackup.enable = true;

  #networking.accessPD = true;

  systemd.mounts = [
    {
      what = "/dev/disk/by-uuid/06ab96b5-b34b-47e7-862d-1410dd0a5425";
      type = "btrfs";
      where = "/usr/local/share/av";
      options = "subvol=@av";
    }
    {
      what = "/dev/disk/by-uuid/213a8de3-da05-40ca-995d-40c1b76eb3ca";
      type = "ext4";
      where = "/var/cache/nginx";
      options = "noexec";
    }
  ];

  services.jellyfin = {
    enable = true;
    # This server can be very slow to start up...
    configTimeout = 120;
    requiredSystemdUnits = ["usr-local-share-av.mount"];
    virtualHost = {
      enable = true;
      fqdn = "jelly.dinwoodie.org";
      forceSecureConnections = true;
      enableACME = true;
    };
    users.initialUser = {
      name = "adam";
      passwordFile = "/etc/nixos/secrets/jellyfin/adam";
    };
    libraries = {
      Music = {
        type = "music";
        paths = ["/usr/local/share/av/music"];
      };
      Films = {
        type = "movies";
        paths = ["/usr/local/share/av/films"];
      };
      TV = {
        type = "tvshows";
        paths = ["/usr/local/share/av/tv"];
      };
      "Fitness stuff" = {
        type = "homevideos";
        paths = ["/usr/local/share/av/fitness"];
        includePhotos = false;
      };
    };
    apiDebugScript = true;
    forceReconfigure = false;
  };
  services.snapper.configs.av = {
    TIMELINE_CREATE = true;
    TIMELINE_CLEANUP = true;
    SUBVOLUME = "/usr/local/share/av";
    ALLOW_USERS = [config.users.me];
    SYNC_ACL = true;
    EMPTY_PRE_POST_CLEANUP = true;
  };

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
    enable = true;
    accessLogPath = "/var/log/nginx/access.log";

    # Cache is on a separate partition, so no need to use an absolute size
    # limit, and can use a small free space limit as there shouldn't be
    # anything else that would use space on that partition.
    cache.sizeLimit = null;
    cache.minFree = "100m";
    # TODO add resolver config to use the AAISP resolvers, assuming I don't
    # manage to get this working with the default system resolver?
  };

  services.postfix.enable = true;

  services.scanToOneDrive = {
    enable = true;
    ftpPasvPortRange = {
      from = 56615;
      to = 56624;
    };
    scannerUser = "ida";
    scannerHashedPasswordFile = ../../../secrets/ida;
  };
}