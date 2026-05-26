{ flake, ... }:
{
  imports = [
    flake.homeModules.default
    flake.homeModules.marvin
  ];
}
