{ pkgs, ... }:
{
  home.packages = [ pkgs.discord ];

  nixpkgs.config.allowUnfreePackages = [
    "discord"
    "discord-unwrapped"
  ];
}
