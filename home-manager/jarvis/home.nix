{ config, ... }:
{
  home.file.".config/systemd/user/timers.target.wants/disk-usage-report.timer".source =
    config.home.file.".config/systemd".source + "/user/disk-usage-report.timer";

  accounts.email.maildirBasePath = "${config.xdg.cacheHome}/mail";

  services.syncthing.enable = true;

  home.stateVersion = "25.11";
}
