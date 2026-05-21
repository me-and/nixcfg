{ config, ... }:
{
  accounts.email.maildirBasePath = "${config.xdg.cacheHome}/mail";

  services.syncthing.enable = true;

  services.rclone = {
    enable = true;
    mountPoints."${config.home.homeDirectory}/OneDrive" = "onedrive:";
  };

  programs.taskwarrior = {
    backup.enable = true;
    checkProjects.enable = true;
  };

  home.stateVersion = "25.11";
}
