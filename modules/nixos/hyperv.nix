{
  config,
  lib,
  options,
  pkgs,
  ...
}: let
  normalUsers = lib.filterAttrs (k: v: v.isNormalUser) config.users.users;
  normalUserNames = lib.mapAttrsToList (k: v: v.name) normalUsers;

  defaultPrio = (lib.mkOptionDefault null).priority;
in {
  config = lib.mkIf config.virtualisation.hypervGuest.enable {
    warnings =
      lib.mkIf
      (options.virtualisation.hypervGuest.videoMode.highestPrio >= defaultPrio)
      [
        ''
          Hyper-V video mode left at default.  Consider setting
          virtualisation.hypervGuest.videoMode.
        ''
      ];
    services.xserver.modules = [pkgs.xorg.xf86videofbdev];
    services.xserver.videoDrivers = ["hyperv_fb"];
    users.groups.video.members = ["gdm"] ++ normalUserNames;
  };
}
