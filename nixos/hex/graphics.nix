{
  pkgs,
  ...
}: {
  environment.systemPackages = [
    #pkgs.displaylink
    pkgs.lact
  ];
  systemd.packages = [pkgs.lact];
  systemd.services.lact.wantedBy = ["graphical.target"];
  boot.kernelPackages = pkgs.linuxPackages_latest;

  #services.xserver.videoDrivers = ["displaylink"];
}
