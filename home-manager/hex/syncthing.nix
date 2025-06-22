{
  config,
  flakeInputs,
  ...
}: let
  cfg = config.services.syncthing;
  inherit (flakeInputs.private) syncthingData;

  allDevices = builtins.attrNames syncthingData.devices;
in {
  services.syncthing = {
    enable = true;
    overrideDevices = true;
    overrideFolders = true;
    settings = {
      devices = builtins.mapAttrs (n: v: {id = v;}) syncthingData.devices;
      folders = builtins.mapAttrs (n: v: v // {id = syncthingData.folders."${n}";}) {
        Documents = {
          devices = allDevices;
          path = config.xdg.userDirs.documents;
          versioning.type = "staggered";
        };
      };
      options.urAccepted = 3;
    };
    tray.enable = true;
  };
}
