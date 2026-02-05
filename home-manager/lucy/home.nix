{ config, ... }:
{
  home.stateVersion = "25.11";

  programs.taskwarrior.backup.enable = true;

  services.syncthing.enable = true;
}
