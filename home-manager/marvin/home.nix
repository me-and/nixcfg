{
  config,
  pkgs,
  personalCfg,
  ...
}:
{
  imports = [
    personalCfg.homeModules.latex
    personalCfg.homeModules.mypy
  ];

  home.stateVersion = "25.11";

  home.packages =
    with pkgs;
    [
      quodlibet-without-gst-plugins # operon
    ]
    ++ (with pkgs.mypkgs; [
      operons
      wavtoopus
    ]);

  programs.taskwarrior.backup.enable = true;

  accounts.email.maildirBasePath = "${config.xdg.cacheHome}/mail";

  services.rclone = {
    enable = true;
    mountPoints."${config.home.homeDirectory}/OneDrive" = "onedrive:";
  };

  services.syncthing.enable = true;
}
