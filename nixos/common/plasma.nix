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
      # I prefer the search interface in Nautilus, the Gnome file manager, to
      # the one that comes with Plasma.  If I'm using Plasma, install Nautilus
      # as well as the indexing tools it uses.
      (pkgs.nautilus or pkgs.gnome.nautilus)

      # Command line clipboard access on Wayland.
      # TODO: how do I make this directly conditional on Waylang being in use,
      # rather than on Plasma implying Wayland?
      pkgs.wl-clipboard
    ];

    # As well as enabling Nautilus, enable the indexing tools it uses.
    services.gnome =
      lib.warnIf
      ((lib ? oldestSupportedReleaseIsAtLeast)
        && lib.oldestSupportedReleaseIsAtLeast 2411)
      ''
        Version handling in ${builtins.toString ./.}/plasma.nix of
        services.gnome renames, introduced in NixOS 24.11, can be safely
        removed.
      ''
      lib.mkMerge [
        (
          if options.services.gnome ? tinysparql
          then {tinysparql.enable = true;}
          else {tracker.enable = true;}
        )
        (
          if options.services.gnome ? localsearch
          then {localsearch.enable = true;}
          else {tracker-miners.enable = true;}
        )
      ];
  }
