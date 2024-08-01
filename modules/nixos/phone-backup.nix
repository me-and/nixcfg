{
  config,
  lib,
  pkgs,
  ...
}: let
  nibbleBackupConfigSet = {
    id,
    label,
    onedrivePath,
  }: let
    safeOnedrivePath = builtins.replaceStrings [" " "/" "\\"] ["-" "-" "-"] onedrivePath;
    rcloneUnitName = "rclone-syncthing-onedrive-mount@" + safeOnedrivePath;
    rcloneFullUnitName = rcloneUnitName + ".service";
    runtimeMountDir = "rclone-syncthing-onedrive/${safeOnedrivePath}";
    mountPath = "/run/${runtimeMountDir}";
  in {
    systemd.services."${rcloneUnitName}" = {
      description = "'rclone mount of \"onedrive:${onedrivePath}\" for phone backup purposes'";
      bindsTo = ["var-cache-rclone.mount"];
      after = [
        "var-cache-rclone.mount"
        "time-sync.target" # Otherwise OneDrive auth doesn't work
      ];
      serviceConfig = {
        Type = "notify";
        CacheDirectory = "rclone";
        CacheDirectoryMode = "0770";
        ConfigurationDirectory = "rclone";
        ConfigurationDirectoryMode = "0770";
        RuntimeDirectory = runtimeMountDir;
        RuntimeDirectoryMode = "0770";
        User = "syncthing";
        Group = "syncthing";

        # TODO This is producing permissions errors.  The mount still unmounts,
        # although I think that's because systemd just kills the rclone process
        # when this doesn't do its job.
        ExecStop = "/run/wrappers/bin/fusermount -u \${RUNTIME_DIRECTORY}";
      };
      reload = "kill -HUP $MAINPID";
      script = ''
        exec ${pkgs.rclone}/bin/rclone mount \
            --config="''${CONFIGURATION_DIRECTORY}"/rclone.conf \
            --cache-dir="''${CACHE_DIRECTORY}" \
            --vfs-cache-mode=full \
            onedrive:${lib.strings.escapeShellArg onedrivePath} \
            "''${RUNTIME_DIRECTORY}"
      '';
      stopIfChanged = true;

      # Need to set PATH such that rclone can find the wrapped version of
      # fusermount.
      path = ["/run/wrappers"];
    };

    # Make sure syncthing can't run unless this mount is up.  I don't want to
    # have syncthing trying to copy things into or out of the empty mountpoint
    # directory.
    systemd.services.syncthing = {
      bindsTo = [rcloneFullUnitName];
      after = [rcloneFullUnitName];
    };

    services.syncthing.settings.folders."${mountPath}" = {
      inherit id label;
      devices = ["Nibble"];
    };
  };
in {
  options = {
    services.nibbleBackup.enable = lib.mkEnableOption "backup of my phone to OneDrive using Syncthing";
  };

  config = lib.mkIf config.services.nibbleBackup.enable (
    lib.mkMerge (
      [
        {
          # Make sure fusermount is in the /run/wrappers/bin directory.
          environment.systemPackages = [pkgs.fuse];

          services.syncthing = {
            enable = true;
            settings.devices.Nibble.id = "LGLQPSI-L65LILM-FJF6DSY-PFMZWSU-I5TUDHQ-HFG4ZCQ-JABHNDK-FIZ7VQM";
          };

          systemd.mounts = [
            {
              what = "/dev/mapper/pi-rclone--cache";
              where = "/var/cache/rclone";
            }
          ];
        }
      ]
      ++ (
        map nibbleBackupConfigSet [
          {
            id = "5yufi-vbxdx";
            label = "Nibble Recordings";
            onedrivePath = "Nibble Recordings";
          }
          {
            id = "bgt9i-d9dvu";
            label = "Nibble Documents";
            onedrivePath = "Documents/Nibble";
          }
          {
            id = "fjkeb-q9afc";
            label = "Nibble Movies";
            onedrivePath = "Videos/Nibble";
          }
          {
            id = "hdqkc-exqkp";
            label = "Nibble Pictures";
            onedrivePath = "Pictures/Nibble";
          }
          {
            id = "i1buc-179ew";
            label = "Nibble Backups";
            onedrivePath = "Nibble Backups";
          }
          {
            id = "oejb6-flq6x";
            label = "Nibble Downloads";
            onedrivePath = "Downloads/Nibble";
          }
          {
            id = "uo4kv-hsefq";
            label = "Nibble Music";
            onedrivePath = "Nibble music";
          }
          {
            id = "xzcgt-hnzhy";
            label = "Nibble DCIM";
            onedrivePath = "Pictures/Nibble DCIM";
          }
          {
            id = "ytfce-eyz4p";
            label = "Nibble misc app media";
            onedrivePath = "Nibble misc app media";
          }
          {
            id = "9uyfa-jo4zb";
            label = "Nibble Seedvault backup";
            onedrivePath = "Nibble Seedvault backup";
          }
        ]
      )
    )
  );
}
