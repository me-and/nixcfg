{
  lib,
  pkgs,
  ...
}: let
  mountpoint = "/run/mum-mac";
  mountpointEscaped = pkgs.escapeSystemdPath mountpoint;

  bindMountpoint = "/run/mum-mac-rebind";
  bindMountpointEscaped = pkgs.escapeSystemdPath bindMountpoint;

  outerVolumeDevicePath = "/dev/mapper/pi-mum--mac";
  outerVolumeDevicePathEscaped = pkgs.escapeSystemdPath outerVolumeDevicePath;

  innerPartitionUuid = "8070817c-6512-3035-997c-8dd5ee05a3ef";
  innerPartitionUuidEscaped = pkgs.escapeSystemdString innerPartitionUuid;

  loopDeviceConfig = let
    commonConfig = {
      unitConfig.RequiresMountsFor = ["%f" "%t"];
      environment = {
        DEVICE_FILE = "%t/%n.device";
      };
      serviceConfig.Type = "oneshot";
      serviceConfig.ExecStartPre = ["${pkgs.coreutils}/bin/rm -f \${DEVICE_FILE}"];
      serviceConfig.StandardOutput = "file:%t/%n.device";
      serviceConfig.StandardError = "journal";
      serviceConfig.ExecStop = pkgs.writeCheckedShellScript {
        name = "setup-loop-device-stop";
        text = ''
          device="$(<"$DEVICE_FILE")"
          ${pkgs.util-linux}/bin/losetup -d "$device"
        '';
      };
      serviceConfig.ExecStopPost = "${pkgs.coreutils}/bin/rm -f \${DEVICE_FILE}";
      serviceConfig.RemainAfterExit = true;
    };
  in {
    systemd.services = {
      "setup-loop-device-ro@" = lib.recursiveUpdate commonConfig {
        description = "Set up %f as a read-only loop device";
        serviceConfig.ExecStart = "${pkgs.util-linux}/bin/losetup -fPr --show %f";
      };
      "setup-loop-device-rw@" = lib.recursiveUpdate commonConfig {
        description = "Set up %f as a read-write loop device";
        serviceConfig.ExecStart = "${pkgs.util-linux}/bin/losetup -fP --show %f";
      };
    };
  };

  mountConfig = {
    environment.systemPackages = [pkgs.bindfs];
    systemd.mounts = [
      {
        what = "/dev/disk/by-uuid/${innerPartitionUuid}";
        where = mountpoint;
        requires = ["setup-loop-device-ro@${outerVolumeDevicePathEscaped}.service"];
        after = [
          "blockdev@${outerVolumeDevicePathEscaped}.target"
          "setup-loop-device-ro@${outerVolumeDevicePathEscaped}.service"
        ];
        #options = "uid=1001,gid=100";  # TODO Fragile
        type = "hfsplus";
      }
      {
        what = mountpoint;
        where = bindMountpoint;
        type = "fuse.bindfs";
        options = "force-user=adam,force-group=users,multithreaded,perms=u=rD:g=:o=";
      }
    ];
  };

  mailStateConfig = {
    systemd.services."mail-state@" = {
      description = "Unit %i state report";
      serviceConfig.Type = "oneshot";
      serviceConfig.ExecStart = let
        reportScript = pkgs.writeCheckedShellScript {
          name = "mailstate.sh";
          bashOptions = ["errexit" "nounset"];
          text = ''
            unit="$1"
            user="$2"
            shorthost="$3"
            longhost="$4"

            unit_state="$(${pkgs.systemd}/bin/systemctl --user show -PActiveState "$unit")"

            # shellcheck disable=SC2312 # systemctl expected to return non-zero
            SYSTEMD_COLORS=True SYSTEMD_URLIFY=False \
                ${pkgs.systemd}/bin/systemctl --user status "$unit" |
                ${pkgs.colourmail}/bin/colourmail \
                    -s "Unit $unit $unit_state on $shorthost" \
                    -r "$user on $shorthost <''${user}@''${longhost}>" \
                    -- "$user"
          '';
        };
      in "${reportScript} %i %u %l %H";
    };
  };

  rcloneConfig = {
    systemd.services.rclone-mum-mac = {
      description = "Copy data from Mum's Mac to OneDrive";
      wants = ["network-online.target"];
      after = ["network-online.target" "time-sync.target"];
      unitConfig.RequiresMountsFor = [bindMountpoint];
      unitConfig.OnFailure = ["mail-state@%n.service"];
      unitConfig.OnSuccess = ["mail-state@%n.service"];
      wantedBy = ["multi-user.target"];
      serviceConfig.User = "adam"; # TODO Fragile
      serviceConfig.Group = "users"; # TODO Fragile
      serviceConfig.Nice = 10;

      serviceConfig.ExecStart = pkgs.writeCheckedShellScript {
        name = "rclone-mum-mac.sh";
        text = ''
          ${pkgs.rclone}/bin/rclone copy \
              --ignore-existing \
              --config=/home/adam/.config/rclone/rclone.conf \
              --cache-dir=/home/adam/.cache/rclone \
              --checksum \
              --modify-window=1s \
              --skip-links \
              --verbose \
              :hasher,remote=/,hashes=quickxor:${lib.escapeShellArg bindMountpoint} \
              onedrive:'Held for other people/Mum/iMac data' || :
          exec ${pkgs.rclone}/bin/rclone check \
              --config=/home/adam/.config/rclone/rclone.conf \
              --cache-dir=/home/adam/.cache/rclone \
              --checksum \
              --modify-window=1s \
              --skip-links \
              :hasher,remote=/,hashes=quickxor:${lib.escapeShellArg bindMountpoint} \
              onedrive:'Held for other people/Mum/iMac data'
        '';
      };
    };
  };
in
  lib.mkMerge [
    loopDeviceConfig
    mountConfig
    mailStateConfig
    rcloneConfig
  ]
