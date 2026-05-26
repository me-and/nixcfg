{ flake, ... }:
{
  imports = [
    flake.homeModules.default
    flake.homeModules.multivac
  ];
}
