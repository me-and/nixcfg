{
  imports = [../common];

  system.stateVersion = "24.05";
  wsl.enable = true;
  networking.hostName = "surface";
  networking.domain = "dinwoodie.org";

  services.postfix = {
    enable = true;
    relayHost = "smtp.tastycake.net";
    relayPort = 587;
  };
}
