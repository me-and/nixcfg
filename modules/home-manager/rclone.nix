{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.rclone;

  escapeSystemdPath = str:
    lib.strings.fileContents (
      pkgs.runCommandLocal "escape" {}
      "${pkgs.systemd}/bin/systemd-escape -p ${lib.strings.escapeShellArg str} >$out"
    );

  waitForTimesync = pkgs.writeCheckedShellScript {
    name = "wait-for-timesync.sh";
    runtimeInputs = [pkgs.inotify-tools];
    purePath = true;
    text = ''
      if [[ -e /run/systemd/timesync/synchronized ]]; then
          exit 0
      fi

      inw_PID= # Avoid shellcheck failures
      coproc inw {
          exec inotifywait \
              -e create,moved_to \
              --include '/synchronized$' \
              /run/systemd/timesync \
              2>&1
      }

      while read -r -u "''${inw[0]}" line; do
          if [[ "$line" = 'Watches established.' ]]; then
              break;
          fi
      done

      if [[ -e /run/systemd/timesync/synchronized ]]; then
          kill "$inw_PID"
          rc=0
          wait "$inw_PID" || rc="$?"
          if (( rc == 143 )); then
              exit 0
          else
              printf 'Unexpected inotifywait return code %s\n' "$rc"
              if (( rc == 0 )); then
                  exit 1
              else
                  exit "$rc"
              fi
          fi
      fi

      time wait "$inw_PID"
    '';
  };

  mountToService = mountpoint: target: let
    escapedMountpoint = escapeSystemdPath mountpoint;
  in {
    "rclone-mount@${escapedMountpoint}" = {
      Unit = {
        Description = "rclone mount of ${target} at ${mountpoint}";
        After = ["time-sync.target"];
      };
      Service = {
        Type = "notify";
        ExecStartPre = "mkdir -vp %f";
        CacheDirectory = "rclone";
        ExecStart = "${pkgs.rclone}/bin/rclone mount --config=%h/.config/rclone/rclone.conf --cache-dir=\${CACHE_DIRECTORY} --vfs-cache-mode=full ${lib.strings.escapeShellArg target} %f";
        # fusermount has to come from the system, because it requires setuid/setgid.
        ExecStop = "fusermount -u %h/%I";
        ExecReload = "kill -HUP $MAINPID";
      };
      Install.WantedBy = ["default.target"];
    };
  };

  systemdConfig =
    lib.attrsets.concatMapAttrs
    (name: value: mountToService name value)
    cfg.mountPoints;
in {
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
      default = {};
    };
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    {
      assertions = [
        {
          assertion = (cfg.mountPoints == {}) || config.systemd.user.enable;
          message = "Rclone mountpoints require the user systemd service.";
        }
      ];

      home.packages = lib.mkMerge [
        [pkgs.rclone]
        (lib.mkIf cfg.includeManPage [pkgs.rclone.man])
      ];

      # This emulates the time-sync configuration for the system Systemd
      # instance.
      systemd.user = {
        targets.time-sync = {
          Unit = {
            Description = "System Time Synchronized";
            Documentation = "man:systemd.special(7)";
            RefuseManualStart = true;
            After = ["time-set.target"];
            Wants = ["time-set.target"];
          };
        };
        services.systemd-time-wait-sync = {
          Unit = {
            Description = "Wait Until Kernel Time Synchronized";
            Documentation = "man:systemd-time-wait-sync.service(8)";
            ConditionCapability = "CAP_SYS_TIME";
            ConditionVirtualization = "!container";
            DefaultDependencies = false;
            Before = ["time-sync.target"];
            Wants = ["time-sync.target"];
            Conflicts = ["shutdown.target"];
            WantedBy = ["basic.target"];
          };
          Service = {
            Type = "oneshot";
            ExecStart = "${pkgs.systemd}/lib/systemd/systemd-time-wait-sync";
            TimeoutStartSec = "infinity";
            RemainAfterExit = true;
          };
        };
      };
    }
    {
      systemd.user.services = systemdConfig;
    }
  ]);
}
