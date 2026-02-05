{ config, ... }:
{
  home.stateVersion = "25.11";

  home.file.".config/systemd/user/timers.target.wants/taskwarrior-monthly.timer".source =
    config.home.file.".config/systemd".source + "/user/taskwarrior-monthly.timer";

  programs.taskwarrior.backup.enable = true;

  services.syncthing.enable = true;
}
