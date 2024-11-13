{
  config,
  lib,
  pkgs,
  ...
}: let
  havePlasma = config.services.desktopManager.plasma6.enable;
in
  lib.mkIf havePlasma {
    environment.systemPackages = with pkgs; [
      # I prefer the search interface in Nautilus, the Gnome file manager, to the
      # one that comes with Plasma.  If I'm using Plasma, install Nautilus as
      # well as the indexing tools it uses.
      gnome.nautilus

      # Command line clipboard access on Wayland.
      # TODO: how do I make this directly conditional on Waylang being in use,
      # rather than on Plasma implying Wayland?
      wl-clipboard
    ];

    # As well as enabling Nautilus, enable the indexing tools it uses.
    services.gnome = {
      tracker.enable = true;
      tracker-miners.enable = true;
    };
  }
