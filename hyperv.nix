{ config, pkgs, lib, ... }:

let
  normalUsers = lib.filterAttrs (k: v: v.isNormalUser) config.users.users;
  normalUserNames = lib.mapAttrsToList (k: v: k) normalUsers;
in
{
  config = {
    boot.kernelParams = [ "nomodeset" ];
    virtualisation.hypervGuest.enable = true;
    services.xserver.modules = [ pkgs.xorg.xf86videofbdev ];
    services.xserver.videoDrivers = "hyperv_fb";
    users.groups.video.members = [ "gdm" ] ++ normalUserNames;
  };
}
