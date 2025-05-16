{
  config,
  pkgs,
  ...
}: let
  # TODO Fix up these dependencies to be a bit more idiomatic rather than just
  # affecting the general Python installation.
  python = pkgs.python3.withPackages (pp: [
    pp.dateutil # Needed for asmodeus
    pp.requests # Needed for petition signing script
  ]);
in {
  home.packages = [python];

  # Ideally this wouldn't be handled here but instead by Nix dependency
  # management -- nothing should rely on the general site environment being set
  # up correctly -- but this is the quick solution while there are plenty of
  # things I care about that aren't yet integrated into Home Manager.
  #
  # TODO Move to using sessionSearchVariables once
  # https://github.com/nix-community/home-manager/commit/277eea1cc7a5c37ea0b9aa8198cd1f2db3d6715c
  # exists
  home.sessionVariables.PYTHONPATH = "$HOME/.local/lib/python3/my-packages:${python}/${python.sitePackages}\${PYTHONPATH:+:$PYTHONPATH}";

  programs.mypy.config.mypy.cache_dir = "${config.xdg.cacheHome}/mypy";
}
