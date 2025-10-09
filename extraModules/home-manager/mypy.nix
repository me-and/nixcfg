{
  config,
  pkgs,
  ...
}: {
  home.packages = [pkgs.mypy];
  xdg.configFile."mypy/config".text = ''
    [mypy]
    cache_dir = ${config.xdg.cacheHome}/mypy
  '';
}
