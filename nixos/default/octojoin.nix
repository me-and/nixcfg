{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.services.octojoin;
in
{
  options.services.octojoin = {
    enable = lib.mkEnableOption "Octojoin";
    configFile = lib.mkOption {
      description = ''
        Path to the Octojoin configuration file.  This will contain the Octopus
        API key and account number, so almost certainly shouldn't be added to
        the Nix store.
      '';
      example = lib.mdLiteral "config.sops.templates.octojoin-conf.path";
    };
    webUI = {
      enable = lib.mkEnableOption "the Octojoin web UI";
      port = lib.mkOption {
        description = "The port on which to run the Octojoin web UI.";
        type = lib.types.port;
        default = 8080;
        example = 80;
      };
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.octojoin = {
      description = "Octojoin Octopus Energy monitoring";
      wants = [ "network-online.service" ];
      after = [ "network-online.service" ];
      serviceConfig = {
        ExecStartPre = lib.concatStringsSep " " [
          (lib.getExe pkgs.mypkgs.octojoin)
          "-test"
          "-config=\${CREDENTIALS_DIRECTORY}/octojoin.yaml"
        ];
        ExecStart = lib.concatStringsSep " " (
          [
            (lib.getExe pkgs.mypkgs.octojoin)
            "-daemon"
            "-config=\${CREDENTIALS_DIRECTORY}/octojoin.yaml"
          ]
          ++ lib.optionals cfg.webUI.enable [
            "-web"
            "-port=${toString cfg.webUI.port}"
          ]
        );
        DynamicUser = true;
        NoNewPrivileges = true;
        PrivateDevices = true;
        PrivateTmp = true;
        ProtectControlGroups = true;
        ProtectKernelLogs = true;
        ProtectKernelModules = true;
        ProtectKernelTunables = true;
        ProtectSystem = "strict";
        # AF_UNIX is required for DNS resolution via systemd-resolved
        RestrictAddressFamilies = [
          "AF_UNIX"
          "AF_INET"
          "AF_INET6"
        ];
        RestrictNamespaces = true;
        RestrictRealtime = true;
        RestrictSUIDSGID = true;
        LockPersonality = true;
        SystemCallArchitectures = "native";
        SystemCallFilter = [ "@system-service" ];
        LoadCredential = "octojoin.yaml:${cfg.configFile}";
        CacheDirectory = "octojoin";
        Environment = [ "HOME=%C/octojoin" ];
      };
      wantedBy = [ "multi-user.target" ];
    };
  };
}
