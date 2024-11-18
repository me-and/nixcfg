{pkgs, ...}: {
  # Disable Gnome packages I don't want.
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
