{ config, ... }:
{
  home.stateVersion = "25.11";

  programs.taskwarrior = {
    backup.enable = true;
    checkProjects.enable = true;
  };

  accounts.email.maildirBasePath = "${config.xdg.cacheHome}/mail";

  services.rclone = {
    enable = true;
    mountPoints."${config.home.homeDirectory}/OneDrive" = "onedrive:";
  };

  services.syncthing.enable = true;
}
