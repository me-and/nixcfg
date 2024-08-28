# This is inherently limited by rclone config including authentication tokens
# that change drequently.  But we can at least provide some useful function...
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.programs.rclone;
  systemdServiceCfg = config.systemd.services;

  rcloneMountSubmodule = {config, ...}: {
    options = {
      what = lib.mkOption {
        type = lib.types.str;
        description = "The rclone path to mount.";
        example = "onedrive:path/to/folder";
      };
      where = lib.mkOption {
        type = lib.types.path;
        description = "Mount path.";
        example = "/mnt";
      };
      unitName = lib.mkOption {
        description = ''
          Name of the systemd service unit that will run the mount, without the
          `.service` part.
        '';
        type = lib.types.str;
      };
      unitFullName = lib.mkOption {
        description = ''
          Full name of the systemd service unit that will run the mount,
          including the `.service` part.
        '';
        readOnly = true;
      };
      needsTime = lib.mkOption {
        description = ''
          Whether rclone needs to wait for the system to have synchronised its
          clock before it can mount the unit.

          This is often necessary for remotes that use time-based authentication
          tokens.
        '';
        type = lib.types.bool;
        default = false;
      };
      needsNetwork = lib.mkOption {
        description = ''
          Whether rclone needs to wait for the system to have external network
          connectivity before it can mount the unit.
        '';
        type = lib.types.bool;
        default = true;
      };
      startWithSystem = lib.mkOption {
        description = ''
          Whether to start the mount process at start of day.  If disabled, the
          mount will only be started if another systemd unit uses it or if the
          mount is started with a manual `systemctl` command.
        '';
        type = lib.types.bool;
        default = false;
      };
      mountOwner = lib.mkOption {
        description = "Username of the user who will own the mountpoint.";
        type = lib.types.str;
        default = "root";
      };
      mountGroup = lib.mkOption {
        description = "Group name that will own the mountpoint.";
        type = lib.types.str;
        default = "root";
      };
      mountDirPerms = lib.mkOption {
        description = "Permissions for directories in the mount.";
        type = lib.types.str;
        default = "0750";
      };
      mountFilePerms = lib.mkOption {
        description = "Permissions for files in the mount.";
        type = lib.types.str;
        default = "0640";
      };
      readOnly = lib.mkOption {
        description = "Whether the mount should provide read-only access";
        default = false;
        type = lib.types.bool;
      };

      extraUnitConfig = lib.mkOption {
        description = ''
          Extra configuration for the systemd unit.  This will be merged with
          the systemd.service.<unitname> configuration.
        '';
        type = lib.types.attrs;
        default = {};
      };

      unitConfig = lib.mkOption {
        internal = true;
      };
    };

    config = let
      unitName = lib.mkDefault "rclone-mount@${pkgs.escapeSystemdPath config.where}";
    in {
      inherit unitName;
      unitFullName = systemdServiceCfg."${config.unitName}".name;

      unitConfig =
        lib.recursiveUpdate
        {
          description = "rclone mount of ${config.what} at ${config.where}";
          after =
            (lib.optional config.needsTime "time-sync.target")
            ++ (lib.optional config.needsNetwork "network-online.target");
          wants = lib.optional config.needsNetwork "network-online.target";
          serviceConfig = {
            Type = "notify";
            CacheDirectory = "rclone";
            CacheDirectoryMode = "0750";
            ConfigurationDirectory = "rclone";
            ConfigurationDirectoryMode = "0750";
            # This sets the user and group for the rclone mount process; the user
            # and group for the mounted directory are set separately.
            User = "rclone";
            Group = "rclone";

            ExecStart = pkgs.writeCheckedShellScript {
              name = "rclone-mount-start-${config.where}";
              text = ''
                mount_owner_info="$(${pkgs.getent}/bin/getent passwd ${lib.escapeShellArg config.mountOwner})"
                IFS=: read -r _ _ uid _ <<<"$mount_owner_info"

                mount_group_info="$(${pkgs.getent}/bin/getent group ${lib.escapeShellArg config.mountGroup})"
                IFS=: read -r _ _ gid _ <<<"$mount_group_info"

                exec ${pkgs.rclone}/bin/rclone mount \
                    --config="''${CONFIGURATION_DIRECTORY}/rclone.conf" \
                    --cache-dir="''${CACHE_DIRECTORY}" \
                    --vfs-cache-mode full \
                    ${lib.optionalString config.readOnly "--read-only"} \
                    --allow-other \
                    --default-permissions \
                    --dir-perms ${lib.escapeShellArg config.mountDirPerms} \
                    --file-perms ${lib.escapeShellArg config.mountFilePerms} \
                    --uid "$uid" \
                    --gid "$gid" \
                    ${lib.escapeShellArg config.what} \
                    ${lib.escapeShellArg config.where}
              '';
            };
            ExecReload = "kill -HUP $MAINPID";
            ExecStop = pkgs.writeCheckedShellScript {
              name = "rclone-mount-stop-${config.where}";
              text = ''
                exec /run/wrappers/bin/fusermount -u ${lib.escapeShellArg config.where}
              '';
            };
          };

          # Need to set PATH such that rclone can find the wrapped version of
          # fusermount.
          # TODO work out if I can add a wrapper to rclone to make this
          # unnecessary.  Which may have the notable advantage of being able to use
          # systemd mount and automount units rather than service units, with all
          # the extra nice bits of automation that provides.
          path = ["/run/wrappers"];

          stopIfChanged = true;

          wantedBy = lib.optional config.startWithSystem "default.target";
        }
        config.extraUnitConfig;
    };
  };
in {
  options.programs.rclone.mounts = lib.mkOption {
    description = "Rclone mountpoints to configure.";
    type = lib.types.listOf (lib.types.submodule rcloneMountSubmodule);
    default = [];
  };

  config = lib.mkIf (cfg.mounts != []) {
    # Make sure fusermount is in the /run/wrappers/bin directory.
    environment.systemPackages = [pkgs.fuse];

    # Allow mountpoints to have permissions that permit other users to access
    # them.  This is needed because the mount processes are run by the rclone
    # user rather than the user who will access them.
    programs.fuse.userAllowOther = true;

    # TODO This doesn't belong here!
    systemd.mounts = [
      {
        what = "/dev/mapper/pi-rclone--cache";
        where = "/var/cache/rclone";
      }
    ];

    # Create the user and group that will run the cache processes.
    users.users.rclone = {
      isSystemUser = true;
      group = "rclone";
    };
    users.groups.rclone = {};

    systemd.services = lib.mergeAttrsList (
      map (u: {"${u.unitName}" = u.unitConfig;}) cfg.mounts
    );
  };
}