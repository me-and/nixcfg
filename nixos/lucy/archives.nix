{pkgs, ...}: {
  systemd.services.rclone-onedrive-check-archives = {
    description = "rclone check archives directory is in sync";
    wants = ["network-online.target" "time-sync.target"];
    after = ["network-online.target" "time-sync.target"];
    unitConfig.RequiresMountsFor = ["/usr/local/share/archives"];
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
          /usr/local/share/archives \
          onedrive:Archives
    '';
  };
  systemd.timers.rclone-onedrive-check-archives = {
    description = "rclone weekly check archives directory is in sync";
    timerConfig = {
      OnCalendar = "weekly";
      AccuracySec = "7d";
      Persistent = true;
      RandomizedOffsetSec = "1w";
      RandomizedDelaySec = "1h";
    };
    wantedBy = ["timers.target"];
  };

  systemd.services.rclone-onedrive-bisync-archives = {
    description = "rclone bisync of the archives directory";
    wants = ["network-online.target" "time-sync.target"];
    after = ["network-online.target" "time-sync.target"];
    before = ["rclone-onedrive-check-archives.service"];
    unitConfig.RequiresMountsFor = ["/usr/local/share/archives"];
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
          /usr/local/share/archives \
          onedrive:Archives
    '';
  };
}
