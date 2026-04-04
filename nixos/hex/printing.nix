{ pkgs, ... }:
{
  services.printing.enable = true;
  services.printing.drivers = with pkgs; [
    cups-kyocera-3500-4500
    hplip # PD GOD HP printers
    cnijfilter2 # Colour printer in Preston
  ];
}
