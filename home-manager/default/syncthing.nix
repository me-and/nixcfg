{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.syncthing;
in
lib.mkIf cfg.enable {
  services.syncthing = {
    overrideDevices = lib.mkDefault true;
    overrideFolders = lib.mkDefault true;
    settings.options.urAccepted = 3;

    settings.gui.user = "adam";
    passwordFile = config.sops.secrets.syncthing.path;

    # The overrideFolders config means this isn't actually used except for
    # dynamically created folders during a Syncthing invocation, but it might
    # be useful in that circumstance, and it's definitely useful as a
    # reference.
    #
    # TODO Set up an activation script to check that these are actually
    # configured?
    settings."defaults/ignores".lines = [
      # Directory metadata
      "(?d).DS_Store" # macOS
      "(?d)desktop.ini" # Windows
      "(?d)Thumbs.db" # Windows
      "(?d).thumbnails" # Something on Android?
      "(?d).directory" # Something on Linux?

      # Links that Windows keeps creating and are system-specific.
      "*.lnk"

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
    syncthing = {
      Unit.After = [ "syncthing-check-ignores.service" ];
      Unit.Requires = [ "syncthing-check-ignores.service" ];
    };
    syncthing-init = {
      Unit.After = [
        "syncthing-check-ignores.service"
        "sops-nix.service"
      ];
      Unit.Requires = [
        "syncthing-check-ignores.service"
        "sops-nix.service"
      ];
    };
    syncthing-check-ignores = {
      Unit.Description = "Check Syncthing folders and .stignore files are set up correctly";
      Service = {
        Type = "oneshot";
        ExecStart = pkgs.mypkgs.writeCheckedShellScript {
          name = "syncthing-check-ignores.sh";
          runtimeInputs = with pkgs; [
            coreutils
            diffutils
          ];
          text =
            let
              stignoreContents = lib.concatLines cfg.settings."defaults/ignores".lines;
              stignoreRefFile = pkgs.writeText "stignore" stignoreContents;

              folderConfigsToCheck = lib.filter (v: v.enable) (builtins.attrValues cfg.settings.folders);
              pathsToCheck = lib.map (lib.getAttr "path") folderConfigsToCheck;
            in
            ''
              rc=0
              for dir in ${lib.escapeShellArgs pathsToCheck}; do
                  if [[ ! -d "$dir" ]]; then
                      # Directory doesn't yet exist, so we can safely create it and
                      # populate the .stignore file.
                      mkdir -p "$dir"
                      cp ${stignoreRefFile} "$dir"/.stignore
                  elif [[ ! -e "$dir"/.stignore ]]; then
                      rc=1
                      printf 'missing stignore file: %s\n' "$dir"/.stignore
                  elif ! cmp --quiet "$dir"/.stignore ${stignoreRefFile}; then
                      rc=1
                      printf 'stignore file with unexpected content: %s\n' "$dir"/.stignore
                  fi
              done

              if (( rc != 0 )); then
                  printf 'expected content in %s\n' ${stignoreRefFile}
              fi

              exit "$rc"
            '';
        };
      };
    };
  };

  sops.secrets.syncthing = { };
}
