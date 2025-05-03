{
  config,
  lib,
  pkgs,
  ...
}: let
  vpnConfigTemplate = builtins.readFile ./pd.ovpn;

  wslEnabled = config.wsl.enable or false;

  # Only need VPN config on non-WSL systems; on WSL systems the VPN will be
  # managed by Windows' OpenVPN client.
  vpnConfig = lib.mkIf (config.networking.accessPD && !wslEnabled) {
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

  mountConfig = lib.mkIf config.networking.accessPD {
    fileSystems."/usr/share/gonzo" = let
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
        (lib.mkIf (!wslEnabled) [
          "x-systemd.requires=openvpn-pdnet.service"
          "x-systemd.after=openvpn-pdnet.service"
        ])
      ];
    in {
      device = "//gonzo.pdnet.local/Profound Decisions";
      fsType = "cifs";
      options = mountOptions;
    };
    environment.systemPackages = [pkgs.cifs-utils];
  };
in {
  options.networking.accessPD = lib.mkEnableOption "PD remote network access";

  config = lib.mkMerge [vpnConfig mountConfig];
}
