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

    # Without this, I'm seeing the GUI completely fail to load on Hyper-V after
    # 33f385442cd4 ([Backport release-24.11] nixos/plasma6: default to Wayland
    # for SDDM (#368084), 2024-12-25)
    #
    # See also
    # https://github.com/NixOS/nixpkgs/issues/372703
    # https://github.com/NixOS/nixpkgs/pull/372743
    services.displayManager.sddm.wayland.enable = false;
  };
}
