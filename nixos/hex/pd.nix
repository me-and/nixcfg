{ lib, personalCfg, ... }:
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

    services.mullvad-vpn.enable = lib.mkForce false;
    services.tzupdate.enable = lib.mkForce false;

    # Hopefully improve performance over relatively slow LAN.
    programs.ssh.extraConfig = ''
      Compression yes
    '';
  };

  specialisation.tether.configuration = {
    programs.ssh.extraConfig = ''
      Compression yes
    '';
  };
}
