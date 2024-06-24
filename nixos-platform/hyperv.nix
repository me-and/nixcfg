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
  options.system.isHyperV = lib.mkEnableOption "Hyper-V configuration";

  config = lib.mkIf config.system.isHyperV {
    warnings =
      lib.optional
      (options.virtualisation.hypervGuest.videoMode.highestPrio == defaultPriority)
      ''
        Hyper-V video mode left at default.  Consider setting
        virtualisation.hypervGuest.videoMode.
      '';
    boot.kernelParams = ["nomodeset"];
    virtualisation.hypervGuest.enable = true;
    services.xserver.modules = [pkgs.xorg.xf86videofbdev];
    services.xserver.videoDrivers = ["hyperv_fb"];
    users.groups.video.members = ["gdm"] ++ normalUserNames;
  };
}
