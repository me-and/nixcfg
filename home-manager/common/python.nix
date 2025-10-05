{
  config,
  pkgs,
  ...
}: let
  # TODO Fix up these dependencies to be a bit more idiomatic rather than just
  # affecting the general Python installation.
  python = pkgs.python3.withPackages (pp: [
    pp.requests # Needed for petition signing script
    (pkgs.mypkgs.asmodeus.override {python3Packages = pp;})
  ]);
in {
  home.packages = [python];

  programs.mypy.config.mypy.cache_dir = "${config.xdg.cacheHome}/mypy";
}
