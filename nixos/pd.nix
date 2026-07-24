{
  lib,
  pkgs,
  personalCfg,
  ...
}:
{
  specialisation.pd.configuration = {
    # Want to be able to serve the local store as https://<localip>:5000 as an
    # easier alternative to providing SSH connections to all the remote hosts.
    imports = [ personalCfg.nixosModules.nix-serve ];

    networking.pd.vpn = lib.mkForce false;
    networking.hosts."10.0.0.5" = [
      "profounddecisions.co.uk"
      "www.profounddecisions.co.uk"
      "gonzo.pdnet.local"
    ];

    services.tzupdate.enable = lib.mkForce false;

    # Hopefully improve performance over relatively slow LAN.
    programs.ssh.extraConfig = ''
      Compression yes
    '';

    # Add printing configuration.
    services.printing = {
      enable = true;
      drivers = [ pkgs.hplip ];
    };
    hardware.printers = {
      ensureDefaultPrinter = lib.mkForce "GOD_B";
      ensurePrinters = [
        {
          name = "GOD_A";
          description = "GOD A";
          model = "HP/hp-laserjet_m604_m605_m606-ps.ppd.gz";
          deviceUri = "ipp://10.0.0.80/ipp/print";
          ppdOptions = {
            PageSize = "A4";
            Duplex = "None";
            MediaType = "Plain";
            HPOption_Duplexer = "True";
            HPOption_Tray3 = "HP500SheetInputTray";
            HPOption_Tray4 = "HP500SheetInputTray";
          };
        }
        {
          name = "GOD_B";
          description = "GOD B";
          model = "HP/hp-laserjet_m604_m605_m606-ps.ppd.gz";
          deviceUri = "ipp://10.0.0.81/ipp/print";
          ppdOptions = {
            PageSize = "A4";
            Duplex = "None";
            MediaType = "Plain";
            HPOption_Duplexer = "True";
            HPOption_Tray3 = "HP500SheetInputTray";
            HPOption_Tray4 = "HP500SheetInputTray";
          };
        }
      ];
    };
  };
}
