{ flake, ... }:
{
  imports = [
    flake.nixosModules.default
    flake.nixosModules.jarvis
  ];
}
