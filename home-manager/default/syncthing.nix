{ config, lib, ... }:
lib.mkIf config.services.syncthing.enable {
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
      "(?d).DS_Store"
      "(?d)desktop.ini"
      "(?d)Thumbs.db"
      "*.lnk"
      "~$*"
      ".~lock.*#"
      ".*.swp"
      ".rsync-partial"
      ".rsync-tmp"
      ".unison.*"
      "*.download"
      "*.crdownload"
      ".Trash-*"
    ];
  };

  sops.secrets.syncthing = { };
  systemd.user.services.syncthing-init.Unit.After = [ "sops-nix.service" ];
}
