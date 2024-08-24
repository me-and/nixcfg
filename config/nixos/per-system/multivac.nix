{
  config,
  lib,
  ...
}:
lib.mkIf (config.system.name == "multivac") {
  system.stateVersion = "24.05";
  system.isWsl = true;
  networking.domain = "dinwoodie.org";

  networking.accessPD = true;

  services.postfix = {
    enable = true;
    relayHost = "smtp.tastycake.net";
    relayPort = 587;
  };
}
