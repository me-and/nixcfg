{
  config,
  lib,
  options,
  pkgs,
  ...
}: let
  normalUsers = lib.filterAttrs (k: v: v.isNormalUser) config.users.users;
  normalUserNames = lib.mapAttrsToList (k: v: k) normalUsers;

  defaultPriority = (lib.mkOptionDefault {}).priority;
in {
  config = lib.mkIf config.virtualisation.hypervGuest.enable {
    warnings =
      lib.optional
      (options.virtualisation.hypervGuest.videoMode.highestPrio == defaultPriority)
      ''
        Hyper-V video mode left at default.  Consider setting
        virtualisation.hypervGuest.videoMode.
      '';
    boot.kernelParams = ["nomodeset"];
    services.xserver.modules = [pkgs.xorg.xf86videofbdev];
    services.xserver.videoDrivers = ["hyperv_fb"];
    users.groups.video.members = ["gdm"] ++ normalUserNames;
  };
}
