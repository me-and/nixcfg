{ lib, ... }:
{
  specialisation.pd.configuration = {
    networking.pd.vpn = lib.mkForce false;
    networking.hosts."10.0.0.5" = [
      "profounddecisions.co.uk"
      "www.profounddecisions.co.uk"
      "gonzo.pdnet.local"
    ];

    services.mullvad-vpn.enable = lib.mkForce false;
    services.tzupdate.enable = lib.mkForce false;
  };
}
