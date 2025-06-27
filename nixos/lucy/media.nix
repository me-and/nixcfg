{
  config,
  lib,
  pkgs,
  ...
}: let
  # Check times all randomly generated.
  mediaDirectories = [
    {
      local = "music";
      onedrive = "Music";
      libraryName = "Music";
      libraryType = "music";
      includePhotos = true;
      checkTime = "Thu 09:05:10";
    }
    {
      local = "films";
      onedrive = "Films";
      libraryName = "Films";
      libraryType = "movies";
      includePhotos = true;
      checkTime = "Tue 08:18:08";
    }
    {
      local = "tv";
      onedrive = "TV";
      libraryName = "TV";
      libraryType = "tvshows";
      includePhotos = true;
      checkTime = "Mon 02:04:56";
    }
    {
      local = "fitness";
      onedrive = "Fitness videos";
      libraryName = "Fitness stuff";
      libraryType = "homevideos";
      includePhotos = false;
      checkTime = "Tue 17:06:42";
    }
  ];

  perMediaDirConfig = d: {
    programs.rclone.mounts = [
      {
        what = ":hasher,remote=/,hashes=quickxor:/run/av/${d.local}";
        where = "/usr/local/share/av/${d.local}";
        needsNetwork = false;
        mountOwner = "jellyfin";
        mountGroup = "jellyfin";
        mountDirPerms = "0775";
        mountFilePerms = "0664";
        cacheMode = "writes";
        extraRcloneArgs = ["--vfs-fast-fingerprint" "--vfs-cache-min-free-space=1G"];
        extraUnitConfig = {
          unitConfig.RequiresMountsFor = ["/run/av"];
          serviceConfig.ExecStartPre = [
            "${pkgs.coreutils}/bin/mkdir -p /usr/local/share/av/${d.local}"
          ];
        };
      }
    ];

    services.jellyfin = {
      requiredSystemdUnits = ["rclone-mount@usr-local-share-av-${d.local}.service"];
      libraries."${d.libraryName}" = {
        type = d.libraryType;
        paths = ["/usr/local/share/av/${d.local}"];
        includePhotos = d.includePhotos;
      };
    };

    # Config for checking the local files match the ones on OneDrive.
    systemd.services."rclone-onedrive-check-${d.local}" = {
      description = "rclone check ${d.local} directory is in sync";
      wants = ["network-online.target" "time-sync.target"];
      after = ["network-online.target" "time-sync.target"];
      unitConfig.RequiresMountsFor = ["/run/av/${d.local}"];
      serviceConfig = {
        User = "rclone";
        Group = "rclone";
        Type = "oneshot";
        CacheDirectory = "rclone";
        CacheDirectoryMode = "0770";
        ConfigurationDirectory = "rclone";
        ConfigurationDirectoryMode = "0770";
        Nice = 5;
      };
      script = ''
        exec ${pkgs.rclone}/bin/rclone check \
            --config="$CONFIGURATION_DIRECTORY"/rclone.conf \
            --cache-dir="$CACHE_DIRECTORY" \
            --checksum \
            --modify-window=1s \
            --verbose \
            :hasher,remote=/,hashes=quickxor:/run/av/${lib.escapeShellArg d.local} \
            onedrive:${lib.escapeShellArg d.onedrive}
      '';
    };
    systemd.timers."rclone-onedrive-check-${d.local}" = {
      description = "rclone weekly check ${d.local} directory is in sync";
      timerConfig = {
        OnCalendar = d.checkTime;
        AccuracySec = "7d";
        Persistent = true;
      };
      wantedBy = ["timers.target"];
    };

    systemd.services."rclone-onedrive-bisync-${d.local}" = {
      description = "rclone bisync of the ${d.local} directory";
      wants = ["network-online.target" "time-sync.target"];
      after = ["network-online.target" "time-sync.target"];
      unitConfig.RequiresMountsFor = ["/run/av/${d.local}"];
      serviceConfig = {
        User = "rclone";
        Group = "rclone";
        Type = "oneshot";
        CacheDirectory = "rclone";
        CacheDirectoryMode = "0770";
        ConfigurationDirectory = "rclone";
        ConfigurationDirectoryMode = "0770";
        Nice = 5;
      };
      script = ''
        exec ${pkgs.rclone}/bin/rclone bisync \
            --config="$CONFIGURATION_DIRECTORY"/rclone.conf \
            --cache-dir="$CACHE_DIRECTORY" \
            --checksum \
            --workdir="$CACHE_DIRECTORY"/bisync \
            --modify-window=1s \
            --resilient \
            --recover \
            --exclude='.rsync-*/*' \
            :hasher,remote=/,hashes=quickxor:/run/av/${lib.escapeShellArg d.local} \
            onedrive:${lib.escapeShellArg d.onedrive}
      '';
    };
  };

  commonConfig = {
    systemd.mounts = [
      {
        what = "/dev/disk/by-uuid/06ab96b5-b34b-47e7-862d-1410dd0a5425";
        type = "btrfs";
        where = "/run/av";
        options = "subvol=@av,noexec";
        mountConfig.RuntimeDirectory = "av";
      }
    ];

    services.jellyfin = {
      enable = true;
      # This server can be very slow to start up...
      configTimeout = 120;
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
      apiDebugScript = true;
      forceReconfigure = false;
    };

    services.snapper.configs.av = {
      TIMELINE_CREATE = true;
      TIMELINE_CLEANUP = true;
      SUBVOLUME = "/run/av";
      ALLOW_USERS = [config.users.me];
      SYNC_ACL = true;
      EMPTY_PRE_POST_CLEANUP = true;
    };
  };
in
  lib.mkMerge ([commonConfig] ++ (map perMediaDirConfig mediaDirectories))
