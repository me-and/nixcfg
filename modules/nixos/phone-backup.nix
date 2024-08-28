{
  config,
  lib,
  ...
}: let
  nibbleBackupConfigSet = {
    id,
    label,
    onedrivePath,
  }: let
    safeOnedrivePath = lib.strings.sanitizeDerivationName onedrivePath;
    runtimeMountDir = "rclone-syncthing-onedrive/${safeOnedrivePath}";
    mountPath = "/run/${runtimeMountDir}";
  in {
    programs.rclone.mounts = [
      {
        what = "onedrive:${onedrivePath}";
        where = mountPath;
        extraUnitConfig = {
          serviceConfig.RuntimeDirectory = runtimeMountDir;
        };
        needsTime = true;
        needsNetwork = true;
        mountOwner = config.services.syncthing.user;
      }
    ];

    # Make sure syncthing can't run unless this mount is up.  I don't want to
    # have syncthing trying to copy things into or out of the empty mountpoint
    # directory.
    systemd.services.syncthing = let
      # This should only return a singleton, but it's a filter so it returns a
      # list, and we can use that directly.
      mountUnitNames =
        map (m: m.unitFullName)
        (
          builtins.filter
          (m: m.where == mountPath)
          config.programs.rclone.mounts
        );
    in {
      bindsTo = mountUnitNames;
      after = mountUnitNames;
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
          services.syncthing = {
            enable = true;
            settings.devices.Nibble.id = "LGLQPSI-L65LILM-FJF6DSY-PFMZWSU-I5TUDHQ-HFG4ZCQ-JABHNDK-FIZ7VQM";
          };
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
