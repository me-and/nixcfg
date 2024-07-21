{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.rclone;

  escapeSystemd = str:
    lib.strings.fileContents (
      pkgs.runCommandLocal "escape" {}
      "${pkgs.systemd}/bin/systemd-escape ${lib.strings.escapeShellArg str} >$out"
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
    escapedMountpoint = escapeSystemd mountpoint;
  in {
    "rclone-mount@${escapedMountpoint}" = {
      Unit = {
        Description = "rclone mount of ${target} at ${mountpoint}";
        Wants = ["timesynced.service"];
        After = ["timesynced.service"];
      };
      Service = {
        Type = "notify";
        ExecStartPre = "mkdir -p %h/%I";
        CacheDirectory = "rclone";
        ExecStart = "${pkgs.rclone}/bin/rclone mount --config=%h/.config/rclone/rclone.conf --cache-dir=\${CACHE_DIRECTORY} --vfs-cache-mode=full ${lib.strings.escapeShellArg target} %h/%I";
        # fusermount has to come from the system, because it requires setuid/setgid.
        ExecStop = "fusermount -u %h/%I";
        ExecReload = "kill -HUP $MAINPID";
      };
      Install.WantedBy = ["default.target"];
    };
  };
in {
  options.services.rclone = {
    enable = lib.mkEnableOption "rclone";
    mountPoints = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      description = ''
        Mount points under the home directory, and the rclone path to mount
        there.
      '';
      example = ''
        {
          OneDrive = "onedrive:";
          GoogleDrive = "gdrive:";
        }
      '';
      default = {};
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [pkgs.rclone];

    assertions = [
      {
        assertion = (cfg.mountPoints == {}) || config.systemd.user.enable;
        message = "Rclone mountpoints require the user systemd service.";
      }
    ];

    systemd.user.services = lib.mkIf (cfg.mountPoints != {}) (
      {
        timesynced = {
          Unit.Description = "waiting for time synchronization to complete";
          Service = {
            Type = "oneshot";
            RemainAfterExit = true;
            ExecStart = waitForTimesync;
          };
        };
      }
      // (lib.attrsets.concatMapAttrs (name: value: mountToService name value) cfg.mountPoints)
    );
  };
}
