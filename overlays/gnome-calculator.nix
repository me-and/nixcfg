final: prev: {
  gnome-calculator =
    final.lib.warnIf
    ((final.lib ? oldestSupportedReleaseIsAtLeast)
      && final.lib.oldestSupportedReleaseIsAtLeast 2411)
    ''
      Handling of pkgs.gnome.gnome-calculator being renamed to
      pkgs.gnome-calculator in ${builtins.toString ./.}/home.nix can be safely
      removed.
    ''
    (prev.gnome-calculator or prev.gnome.gnome-calculator);
}
