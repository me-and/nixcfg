# Not a good backup solution.  A better one is waiting for
# https://github.com/borgbackup/borg/issues/6602
{
  config,
  lib,
  mylib,
  pkgs,
  ...
}:
let
  cfg = config.services.rcloneBackups;
  rclone = lib.getExe cfg.rclonePackage;
  flock = lib.getExe' pkgs.util-linux "flock";
in
{
  options.services.rcloneBackups = {
    enable = lib.mkEnableOption "my rclone backup configuration";
    rclonePackage = lib.mkPackageOption pkgs "rclone" { };
    commonArgs = lib.mkOption {
      description = "Extra arguments to supply to all `rclone` commands.";
      type = with lib.types; listOf str;
      default = [ ];
    };
    commonExcludes = lib.mkOption {
      description = ''
        Paths, in the format used by rclone's `--exclude-from`, to exclude from
        `rclone` commands.

        See https://rclone.org/filtering/ for information on the syntax.
      '';
      type = with lib.types; listOf str;
      default = [ ];
    };
    folders = lib.mkOption {
      description = "Folders to back up";
      type = lib.types.listOf (
        lib.types.submodule (
          { config, lib, ... }:
          {
            options = {
              localPath = lib.mkOption {
                description = "Local path to back up";
                type = lib.types.externalPath;
              };
              remotePath = lib.mkOption {
                description = "Remote path to back up to";
                type = lib.types.nonEmptyStr;
              };
              excludes = lib.mkOption {
                description = "Patterns to exclude from sync";
                type = with lib.types; listOf str;
                default = [ ];
              };
              checkAccessFile = lib.mkOption {
                description = ''
                  Filename to use with rclone's `--check-access` argument with
                  `rclone bisync` commands.  Set to `null` to disable using
                  this rclone feature.
                '';
                type =
                  with lib.types;
                  nullOr (pathWith {
                    absolute = false;
                  });
                default = ".rclone_access_check";
              };
              extraServiceConfig = lib.mkOption {
                description = ''
                  Extra configuration to be merged with all systemd service
                  units affecting this folder.  Merged with every systemd
                  service unit using `lib.recursiveUpdate`.
                '';
                default = { };
                example = {
                  Unit.AssertPathIsMountPoint = "<localPath>";
                };
              };

              instanceName = lib.mkOption {
                description = "Instance name for the systemd units";
                internal = true;
                default = mylib.escapeSystemdPath config.localPath;
              };
              excludeFile = lib.mkOption {
                description = ''
                  Path to a file listing the paths to exclude, or null if there
                  isn't anything to exclude.
                '';
                internal = true;
                default =
                  let
                    excludes = cfg.commonExcludes ++ config.excludes;
                  in
                  if excludes == [ ] then null else pkgs.writeText "rclone-excludes" (lib.concatLines excludes);
              };
              timerUnits = lib.mkOption {
                description = "Systemd timer units for this module";
                internal = true;
                default = {
                  "rclone-check@${config.instanceName}" = {
                    Unit.Description = "Weekly rclone check of ${config.localPath} vs ${config.remotePath}";
                    Timer = {
                      OnCalendar = "weekly";
                      AccuracySec = "4h";
                      RandomizedDelaySec = "4h";
                      RandomizedOffsetSec = "7d";
                      Persistent = true;
                    };
                    Install.WantedBy = [ "timers.target" ];
                  };
                };
              };
              serviceUnits = lib.mkOption {
                description = "Systemd service units for this module";
                internal = true;
                default =
                  let
                    buildRcloneCmd =
                      cmd: extraArgs: paths:
                      [
                        rclone
                        cmd
                      ]
                      ++ cfg.commonArgs
                      ++ extraArgs
                      ++ (lib.optional (config.excludeFile != null) "--exclude-from=${config.excludeFile}")
                      ++ paths;
                    buildFlockedExecCmd =
                      cmd: extraRcloneArgs: paths:
                      lib.concatStringsSep " " (
                        [
                          flock
                          "--no-fork"
                          "%t/rclonemisc"
                        ]
                        ++ (builtins.map mylib.escapeSystemdExecArg (buildRcloneCmd cmd extraRcloneArgs paths))
                      );
                  in
                  lib.mapAttrs (n: v: lib.recursiveUpdate v config.extraServiceConfig) {
                    "rclone-sync@${config.instanceName}" = {
                      Unit.Description = "rclone sync of ${config.localPath} to ${config.remotePath}";
                      Service.ExecStart =
                        buildFlockedExecCmd "sync"
                          [ ]
                          [
                            config.localPath
                            config.remotePath
                          ];
                      Service.Nice = 19;
                      Service.IOSchedulingClass = "idle";
                      Service.RestartForceExitStatus = [
                        "SIGHUP"
                        "SIGTERM"
                        "SIGINT"
                        "SIGPIPE"
                      ];
                      Service.StartLimitIntervalSec = "1w";
                      Service.StartLimitBurst = 3;
                    };
                    "rclone-rsync@${config.instanceName}" = {
                      Unit.Description = "rclone sync of ${config.localPath} to ${config.remotePath}";
                      Unit.Conflicts = [ "rclone-sync@${config.instanceName}.service" ];
                      Service.ExecStart =
                        buildFlockedExecCmd "sync"
                          [ ]
                          [
                            config.remotePath
                            config.localPath
                          ];
                      Service.Nice = 19;
                      Service.IOSchedulingClass = "idle";
                      Service.RestartForceExitStatus = [
                        "SIGHUP"
                        "SIGTERM"
                        "SIGINT"
                        "SIGPIPE"
                      ];
                      Service.StartLimitIntervalSec = "1w";
                      Service.StartLimitBurst = 3;
                    };
                    "rclone-bisync@${config.instanceName}" = {
                      Unit.Description = "rclone bisync of ${config.localPath} with ${config.remotePath}";
                      Unit.Conflicts = [
                        "rclone-sync@${config.instanceName}.service"
                        "rclone-rsync@${config.instanceName}.service"
                      ];
                      Service.ExecStart =
                        buildFlockedExecCmd "bisync"
                          (
                            [
                              "--max-lock=24h"
                              "--resilient"
                            ]
                            ++ lib.optionals (config.checkAccessFile != null) [
                              "--check-access"
                              "--check-filename=${config.checkAccessFile}"
                            ]
                          )
                          [
                            config.localPath
                            config.remotePath
                          ];
                      Service.Nice = 19;
                      Service.IOSchedulingClass = "idle";
                      Service.RestartForceExitStatus = [
                        "SIGHUP"
                        "SIGTERM"
                        "SIGINT"
                        "SIGPIPE"
                      ];
                      Service.StartLimitIntervalSec = "1w";
                      Service.StartLimitBurst = 3;
                    };
                    "rclone-check@${config.instanceName}" = {
                      Unit.Description = "rclone check of ${config.localPath} to ${config.remotePath}";
                      Unit.After = [
                        "rclone-sync@${config.instanceName}.service"
                        "rclone-rsync@${config.instanceName}.service"
                        "rclone-bisync@${config.instanceName}.service"
                      ];
                      Service.ExecStart =
                        buildFlockedExecCmd "check"
                          [ ]
                          [
                            config.localPath
                            config.remotePath
                          ];
                      Service.Nice = 19;
                      Service.IOSchedulingClass = "idle";
                      Service.RestartForceExitStatus = [
                        "SIGHUP"
                        "SIGTERM"
                        "SIGINT"
                        "SIGPIPE"
                      ];
                      Service.StartLimitIntervalSec = "1w";
                      Service.StartLimitBurst = 3;
                    };
                  };
              };
            };
          }
        )
      );
    };
  };

  config.services.rcloneBackups = {
    enable = true;
    commonArgs = [ "--modify-window=1s" ];
    commonExcludes =
      let
        syncthingExcludes = config.services.syncthing.settings."defaults/ignores".lines;

        # Check for patterns in my Syncthing ignores that I haven't (yet) set
        # up this code to munge into something acceptable for rclone.
        problems = lib.filter (
          x:
          (lib.hasPrefix "!" x)
          || (lib.hasPrefix "#include" x)
          || (lib.hasPrefix "(?i)" x)
          || (lib.hasPrefix "//" x)
          || (lib.hasPrefix "#escape" x)
          || (lib.hasPrefix " " x)
          || (lib.hasInfix "{{" x)
          || (lib.hasInfix "[!" x)
        ) syncthingExcludes;

        # Make the following changes to the list of syncthingExcludes:
        #
        # - Remove any leading "(?d)", since that's a directive for Syncthing only.
        # - If the entry doesn't have a "/" at the end, include versions both
        #   with and without it, since Syncthing would ignore that entry if
        #   it's a file or a directory, whereas without the "/", rclone will
        #   only exclude the file.
        mungedExcludes = lib.concatMap (
          x:
          let
            safe = lib.removePrefix "(?d)" x;
          in
          if lib.hasSuffix "/" safe then
            [ safe ]
          else
            [
              safe
              "${safe}/"
            ]
        ) syncthingExcludes;
      in
      assert problems == [ ];
      mungedExcludes;
    folders = [
      {
        localPath = "/usr/local/share/av/audiobooks";
        remotePath = "onedrive:Audiobooks";
      }
      {
        localPath = "/usr/local/share/av/music";
        remotePath = "onedrive:Music";
      }
      {
        localPath = "/usr/local/share/av/films";
        remotePath = "onedrive3:Films";
      }
      {
        localPath = "/usr/local/share/av/fitness";
        remotePath = "onedrive:Fitness videos";
      }
      {
        localPath = "/usr/local/share/av/music videos";
        remotePath = "onedrive:Music Videos";
      }
      {
        localPath = "/usr/local/share/av/tv";
        remotePath = "onedrive4:TV";
      }
      {
        localPath = "/usr/local/share/archives";
        remotePath = "onedrive2:Archives";
      }
      {
        localPath = config.xdg.userDirs.desktop;
        remotePath = "onedrive:Desktop";
      }
      {
        localPath = config.xdg.userDirs.pictures;
        remotePath = "onedrive:Pictures";
      }
      {
        localPath = config.xdg.userDirs.videos;
        remotePath = "onedrive:Videos";
      }
      {
        localPath = config.xdg.userDirs.documents;
        remotePath = "onedrive:Documents";
      }
      {
        localPath = config.xdg.userDirs.publicShare;
        remotePath = "onedrive:Public";
      }
      {
        localPath = config.home.homeDirectory + "/Calibre Library";
        remotePath = "onedrive:Calibre Library";
      }
      {
        localPath = config.home.homeDirectory + "/Playnite backups";
        remotePath = "onedrive:Playnite backups";
      }
      {
        localPath = config.home.homeDirectory + "/Held for other people";
        remotePath = "onedrive:Held for other people";
        extraServiceConfig.Unit.AssertPathIsMountPoint =
          config.home.homeDirectory + "/Held for other people";
      }
    ];
  };

  config.systemd.user = {
    timers = mylib.unionOfDisjointAttrsList (map (f: f.timerUnits) cfg.folders);
    services = mylib.unionOfDisjointAttrsList (map (f: f.serviceUnits) cfg.folders);
  };
}
