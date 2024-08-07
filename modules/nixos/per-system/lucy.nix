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
  ];
  systemd.services.jellyfin = {
    bindsTo = ["usr-local-share-av.mount"];
    after = ["usr-local-share-av.mount"];
  };
  services.jellyfin = {
    enable = true;
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

  # Without this, journalctl shows messages about IPv6 DHCP solicitation every
  # 10s.  AFAICS that *shouldn't* happen because the local version of dhcpcd
  # should have the fix from
  # <https://github.com/NetworkConfiguration/dhcpcd/issues/80>, but it clearly
  # is still happening!
  networking.dhcpcd.IPv6rs = false;

  services.postfix.enable = true;
}
