{ config, lib, ... }:
let
  cfg = config.services.syncthing;

  defaultIgnores = [
    # Directory metadata
    "(?d).DS_Store" # macOS
    "(?d)desktop.ini" # Windows
    "(?d)Thumbs.db" # Windows
    "(?d).thumbnails" # Something on Android?
    "(?d).directory" # Something on Linux?

    # Links that Windows keeps creating and are system-specific.
    "*.lnk"

    # Generic temporary files.
    "*.tmp"
    ".Temp"

    # Temporary editor files.
    "~$*"
    ".~lock.*#"
    ".*.swp"

    # Non-Syncthing file transfers.
    ".rsync-partial" # rsync
    ".rsync-tmp" # rsync
    ".unison.*" # unison
    "*.download" # web browsers (possibly Edge?)
    "*.crdownload" # Google Chrome / Chromium
    ".partial-*" # Unsure, maybe Firefox
    "*.partial" # rclone

    # Deleted files.
    ".Trash-*" # Dolphin and possibly other Linux utils
    ".trashed-*" # Something on Android?
    ".caltrash" # Calibre

    # Syncthing metadata.  Normally Syncthing ignores these itself, but when
    # I'm syncing, say /home/adam and /home/adam/Documents, Syncthing will
    # ignore the files in the roots of each sync'd directory, but try to sinc
    # /home/adam/Documents/.st* files in /home/adam/Documents in the
    # /home/adam share.
    ".stversions"
    ".stfolder"
    ".stignore"
    ".syncthing.*.tmp"
  ];
in
{
  options.services.syncthing.settings.folders = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule {
        config.ignorePatterns = lib.mkDefault defaultIgnores;
      }
    );
  };

  config = lib.mkIf cfg.enable {
    services.syncthing = {
      overrideDevices = lib.mkDefault true;
      overrideFolders = lib.mkDefault true;
      settings.options.urAccepted = 3;

      guiCredentials = {
        username = "adam";
        passwordFile = config.sops.secrets.syncthing.path;
      };

      settings.folders.Public = {
        path = config.xdg.userDirs.publicShare;
        devices = builtins.attrNames cfg.settings.devices;
        rescanIntervalS = 7 * 24 * 60 * 60;
        versioning = {
          type = "staggered";
          params.maxAge = toString (365 * 24 * 60 * 60);
        };
      };
    };

    systemd.user.services = {
      # `systemctl --user start syncthing.service` should also start the
      # configuration unit.
      syncthing = {
        Unit.Wants = [ "syncthing-init.service" ];
      };

      syncthing-init = {
        Unit.After = [ "sops-nix.service" ];
        Unit.Requires = [ "sops-nix.service" ];
      };
    };

    sops.secrets.syncthing = { };
  };
}
