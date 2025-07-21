{lib, ...}: {
  services.syncthing = {
    overrideDevices = lib.mkDefault true;
    overrideFolders = lib.mkDefault true;
    settings.options.urAccepted = 3;

    # The overrideFolders config means this isn't actually used except for
    # dynamically created folders during a Syncthing invocation, but it might
    # be useful in that circumstance, and it's definitely useful as a
    # reference.
    settings."defaults/ignores".lines = [
      "(?d).DS_Store"
      "(?d)desktop.ini"
      "(?d)Thumbs.db"
      "~$*"
      ".*.swp"
      ".rsync-partial"
      ".rsync-tmp"
      ".unison.*"
      "*.crdownload"
    ];
  };
}
