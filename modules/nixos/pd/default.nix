{
  config,
  lib,
  ...
}: let
  currentDir = builtins.toString ./.;
  secretsDir = builtins.toString ../../../secrets;

  vpnConfigTemplate = builtins.readFile ./pd.ovpn;
in {
  options.networking.accessPD = lib.mkEnableOption "PD remote network access";

  config = lib.mkIf config.networking.accessPD {
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
          "${currentDir}/pd.crt"
          "${currentDir}/me.crt"
          "${secretsDir}/my-pd-key.crt"
        ]
        vpnConfigTemplate;
    };
  };
}
