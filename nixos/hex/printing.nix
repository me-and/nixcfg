{ mylib, pkgs, ... }:
{
  services.printing.enable = true;
  services.printing.drivers = with pkgs; [
    mypkgs.cups-kyocera-ecosys-ma3500cix
    hplip # PD GOD HP printers
    cnijfilter2 # Colour printer in Preston
  ];

  nixpkgs.config.allowUnfreePackages = [
    "cnijfilter2"
  ];

}
