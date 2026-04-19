{ pkgs, ... }:
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

  hardware.printers = {
    ensureDefaultPrinter = "Kyocera";
    ensurePrinters = [
      {
        name = "Kyocera";
        description = "Kyocera ECOSYS MA3500cix";
        model = "Kyocera/Kyocera_ECOSYS_MA3500cix.ppd";
        deviceUri = "dnssd://Kyocera%20ECOSYS%20MA3500cix._ipps._tcp.local/?uuid=4509a320-0031-0074-011d-00f91f8d23d9";
        ppdOptions = {
          PageSize = "A4";
          Duplex = "DuplexNoTumble";
          MediaType = "Plain";
        };
      }
    ];
  };
}
