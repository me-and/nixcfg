{
  services.syncthing = {
    overrideDevices = true;
    overrideFolders = true;

    openDefaultPorts = true;

    settings.options = {
      urAccepted = 3;
      localAnnouncePort = 21027;
      localAnnounceEnabled = true;
    };
  };
}
