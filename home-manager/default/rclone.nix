{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.rclone;

  mountToService =
    mountpoint: target:
    let
      escapedMountpoint = pkgs.mylib.escapeSystemdPath mountpoint;
    in
    {
      "rclone-mount@${escapedMountpoint}" = {
        Unit = {
          Description = "rclone mount of ${target} at ${mountpoint}";
          After = [ "time-sync.target" ];
        };
        Service = {
          Type = "notify";
          ExecStartPre = "/run/current-system/sw/bin/mkdir -vp %f";
          CacheDirectory = "rclone";
          ExecStart = "${pkgs.rclone}/bin/rclone mount --config=%h/.config/rclone/rclone.conf --cache-dir=\${CACHE_DIRECTORY} --vfs-cache-mode=full ${lib.strings.escapeShellArg target} %f";
          # fusermount has to come from the system, because it requires setuid/setgid.
          ExecStop = "/run/wrappers/bin/fusermount -u %f";
          ExecReload = "/run/current-system/sw/bin/kill -HUP $MAINPID";
        };
        Install.WantedBy = [ "default.target" ];
      };
    };

  systemdConfig = lib.attrsets.concatMapAttrs (
    name: value: mountToService name value
  ) cfg.mountPoints;
in
{
  options.services.rclone = {
    enable = lib.mkEnableOption "rclone";
    includeManPage = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to install the rclone man page";
    };
    mountPoints = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      description = "Mount points and the rclone paths to mount there.";
      example = ''
        {
          "/home/adam/OneDrive" = "onedrive:";
          "/home/adam/GDrive" = "gdrive:";
        }
      '';
      default = { };
    };
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        assertions = [
          {
            assertion = (cfg.mountPoints == { }) || config.systemd.user.enable;
            message = "Rclone mountpoints require the user systemd service.";
          }
        ];

        home.packages = lib.mkMerge [
          [ pkgs.rclone ]
          (lib.mkIf cfg.includeManPage [ pkgs.rclone.man ])
        ];

        # This emulates the time-sync configuration for the system Systemd
        # instance.
        systemd.user = {
          targets.time-sync = {
            Unit = {
              Description = "System Time Synchronized";
              Documentation = "man:systemd.special(7)";
              RefuseManualStart = true;
              After = [ "time-set.target" ];
              Wants = [ "time-set.target" ];
            };
          };
          services.systemd-time-wait-sync = {
            Unit = {
              Description = "Wait Until Kernel Time Synchronized";
              Documentation = "man:systemd-time-wait-sync.service(8)";
              ConditionCapability = "CAP_SYS_TIME";
              ConditionVirtualization = "!container";
              DefaultDependencies = false;
              Before = [ "time-sync.target" ];
              Wants = [ "time-sync.target" ];
              Conflicts = [ "shutdown.target" ];
            };
            Service = {
              Type = "oneshot";
              ExecStart = "${pkgs.systemd}/lib/systemd/systemd-time-wait-sync";
              TimeoutStartSec = "infinity";
              RemainAfterExit = true;
            };
            Install.WantedBy = [ "basic.target" ];
          };
        };
      }
      {
        systemd.user.services = systemdConfig;
      }
    ]
  );
}
