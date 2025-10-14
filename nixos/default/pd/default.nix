{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.networking.pd;

  vpnConfigTemplate = builtins.readFile ./pd.ovpn;

  vpnConfig = lib.mkIf cfg.vpn {
    services.openvpn.servers.pdnet = {
      autoStart = false;
      config =
        builtins.replaceStrings
          [
            "@@CA_CERT_PATH@@"
            "@@MY_CERT_PATH@@"
            "@@MY_CERT_KEY@@"
          ]
          [
            "${./pd.crt}"
            "${./me.crt}"
            "/etc/nixos/secrets/my-pd-key.crt"
          ]
          vpnConfigTemplate;
      updateResolvConf = true;
    };
  };

  mountConfig = lib.mkIf cfg.gonzo {
    fileSystems."/usr/share/gonzo" =
      let
        mountOptions = lib.mkMerge [
          [
            "rw"
            "credentials=/etc/nixos/secrets/gonzo-mount-creds"
            "uid=${config.users.me}"
            "gid=users"
            "forceuid"
            "forcegid"
            "file_mode=0600"
            "dir_mode=0700"
            "handlecache"
            # TODO Work out why, at least on Hex, this seems to get automounted
            # every boot, which implies something is trying to access that
            # directory straight away when I'd been hoping the automount would
            # only trigger when I actually tried to access the system.
            # "x-systemd.automount"
            # "x-systemd.mount-timeout=60s"
            "nofail"
            "noauto"
          ]
          (lib.mkIf cfg.vpn [
            "x-systemd.requires=openvpn-pdnet.service"
            "x-systemd.after=openvpn-pdnet.service"
          ])
        ];
      in
      {
        device = "//gonzo.pdnet.local/Profound Decisions";
        fsType = "cifs";
        options = mountOptions;
      };
    environment.systemPackages = [ pkgs.cifs-utils ];
  };
in
{
  options.networking.pd = {
    vpn = lib.mkEnableOption "PD VPN access";
    gonzo = lib.mkEnableOption "mounting the Gonzo file share";
  };

  config = lib.mkMerge [
    vpnConfig
    mountConfig
  ];
}
