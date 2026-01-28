{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.taskwarrior;
in
{
  options.programs.taskwarrior.backup = {
    enable = lib.mkEnableOption "regularly backing up Taskwarrior data";
    destination = lib.mkOption {
      type = lib.types.str;
      default = "${config.xdg.userDirs.documents}/tasks/${config.home.hostName}.json.zst";
      description = "Destination path for the backup file.  Should probably end in .json.zst.";
    };
  };

  config = lib.mkIf cfg.backup.enable {
    systemd.user = {
      services.taskwarrior-backup = {
        Unit = {
          Description = "Backup Taskwarrior data";
          Wants = [ "taskwarrior-wait-for-stability.service" ];
          After = [ "taskwarrior-wait-for-stability.service" ];
        };
        Service = {
          Type = "oneshot";
          ExecStart = pkgs.mypkgs.writeCheckedShellScript {
            name = "taskwarrior-backup.sh";
            runtimeInputs = [
              cfg.package
              pkgs.jq.bin
              pkgs.zstd.bin
            ];
            text = ''
              ${lib.toShellVars { inherit (cfg.backup) destination; }}
              mkdir -p -- "$(dirname -- "$destination")"
              rm -f -- "$destination".tmp
              task export |
                  jq 'map(del(.urgency))' |
                  zstd -o "$destination".tmp
              mv -- "$destination.tmp" "$destination"
            '';
          };
        };
      };

      timers.taskwarrior-backup = {
        Unit.Description = "Regular backup of Taskwarrior data";
        Timer = {
          OnCalendar = "hourly";
          AccuracySec = "1h";
          RandomizedOffsetSec = "1h";
        };
        Install.WantedBy = [ "timers.target" ];
      };
    };
  };
}
