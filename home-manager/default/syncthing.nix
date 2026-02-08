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
      "(?d).DS_Store"
      "(?d)desktop.ini"
      "(?d)Thumbs.db"
      "(?d).thumbnails"
      "(?d).directory"

      # Links that Windows keeps creating and are system-specific.
      "*.lnk"

      # Temporary editor files.
      "~$*"
      ".~lock.*#"
      ".*.swp"

      # Non-Syncthing file transfers.
      ".rsync-partial"
      ".rsync-tmp"
      ".unison.*"
      "*.download"
      "*.crdownload"
      ".partial-*"

      # Deleted files.
      ".Trash-*"
      ".trashed-*"

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
  };

  home.activation.checkSyncthingIgnores =
    let
      stignoreContents = lib.concatLines cfg.settings."defaults/ignores".lines;
      stignoreRefFile = pkgs.writeText "stignore" stignoreContents;

      folderConfigsToCheck = lib.filter (v: v.enable) (builtins.attrValues cfg.settings.folders);
      pathsToCheck = lib.map (lib.getAttr "path") folderConfigsToCheck;
    in
    lib.hm.dag.entryBefore [ "writeBoundary" ] ''
      for dir in ${lib.escapeShellArgs pathsToCheck}; do
          if ! cmp --quiet "$dir"/.stignore ${stignoreRefFile}; then
              warnEcho "Syncthing ignore file $dir/.stignore does not match reference ${stignoreRefFile}"
          fi
      done
    '';

  sops.secrets.syncthing = { };
  systemd.user.services.syncthing-init.Unit.After = [ "sops-nix.service" ];
}
