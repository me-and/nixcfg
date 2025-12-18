{
  config,
  pkgs,
  personalCfg,
  ...
}:
{
  imports = [ personalCfg.homeModules.latex ];

  home.stateVersion = "25.11";

  home.file.".config/systemd/user/timers.target.wants/disk-usage-report.timer".source =
    config.home.file.".config/systemd".source + "/user/disk-usage-report.timer";

  home.packages = [
    pkgs.mypkgs.wavtoopus
    pkgs.quodlibet-without-gst-plugins # operon
  ];

  services.syncthing.enable = true;
}
