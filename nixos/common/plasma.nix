{
  config,
  lib,
  options,
  pkgs,
  ...
}: let
  havePlasma = config.services.desktopManager.plasma6.enable;
in
  lib.mkIf havePlasma {
    environment.systemPackages = [
      # Command line clipboard access on Wayland.
      # TODO: how do I make this directly conditional on Waylang being in use,
      # rather than on Plasma implying Wayland?
      pkgs.wl-clipboard
    ];
  }
