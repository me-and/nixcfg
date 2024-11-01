{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.programs.keepassxc;

  mountpoint = "${config.home.homeDirectory}/OneDrive";
  escapedMountpoint = pkgs.escapeSystemdPath mountpoint;
in
  lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = builtins.elem mountpoint (builtins.attrNames config.services.rclone.mountPoints);
        message = "KeePassXC autostart config assumes there's a OneDrive rclone mount";
      }
    ];

    systemd.user.services.warm-keepass-cache = {
      Unit = {
        Description = "Warm up the KeePass file cache";
        Requires = ["rclone-mount@${escapedMountpoint}.service"];
        After = ["rclone-mount@${escapedMountpoint}.service"];
      };
      Service = {
        Type = "oneshot";
        ExecStart = "cat ${mountpoint}/Documents/Passwords/passwords.kdbx";
        StandardOutput = "null";
      };
    };

    programs.keepassxc.autostart = {
      enable = true;
      requires = ["rclone-mount@${escapedMountpoint}.service"];
      after = ["rclone-mount@${escapedMountpoint}.service"];
      wants = ["warm-keepass-cache.service"];
    };
  }
