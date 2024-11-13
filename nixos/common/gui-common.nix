{
  config,
  lib,
  pkgs,
  ...
}: let
  haveGnome = config.services.xserver.desktopManager.gnome.enable;
  havePlasma = config.services.desktopManager.plasma6.enable;
  haveGui = haveGnome || havePlasma;
in
  lib.mkIf haveGui {
    # Both Gnome and Plasma have their own terminal emulators that I prefer to
    # xterm, so don't install xterm just because I'm installing a GUI.
    services.xserver.excludePackages = [pkgs.xterm];
  }
