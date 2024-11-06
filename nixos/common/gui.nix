{
  config,
  lib,
  pkgs,
  ...
}: let
  haveGnome = config.services.xserver.desktopManager.gnome.enable;
  havePlasma = config.services.desktopManager.plasma6.enable;
  haveGui = haveGnome || havePlasma;
in {
  # Both Gnome and Plasma have their own terminal emulators that I prefer to
  # xterm, so don't install xterm just because I'm installing a GUI.
  services.xserver.excludePackages = lib.mkIf haveGui [pkgs.xterm];

  # I prefer the search interface in Nautilus, the Gnome file manager, to the
  # one that comes with Plasma.  If I'm using Plasma, install Nautilus as well
  # as the indexing tools it uses.
  environment.systemPackages = lib.mkIf havePlasma [pkgs.gnome.nautilus];
  services.gnome = lib.mkIf havePlasma {
    tracker.enable = true;
    tracker-miners.enable = true;
  };

  # If I'm using Gnome, remove Gnome packages I don't want.
  environment.gnome.excludePackages = with pkgs; [
    gnome-tour
    gnome.epiphany # Web browser
    gnome.geary # Email client
    gnome.gnome-contacts
    gnome.gnome-calendar
    gnome.gnome-maps
    gnome.gnome-music
    gnome.gnome-weather
    nixos-render-docs # NixOS manual
  ];
}
