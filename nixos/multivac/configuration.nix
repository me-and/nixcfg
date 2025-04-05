{
  imports = [../common];

  system.stateVersion = "24.05";
  wsl.enable = true;
  networking.hostName = "multivac";
  networking.domain = "dinwoodie.org";

  networking.accessPD = true;

  services.postfix = {
    enable = true;
    relayHost = "smtp.tastycake.net";
    relayPort = 587;
  };
}
