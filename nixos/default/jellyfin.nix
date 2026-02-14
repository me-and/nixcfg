{
  config,
  lib,
  options,
  pkgs,
  utils,
  ...
}:
let
  cfg = config.services.jellyfin;

  inherit (lib)
    mkIf
    mkMerge
    mkEnableOption
    mkOption
    ;

  mkDisableOption =
    text:
    mkEnableOption text
    // {
      default = true;
      example = false;
    };
in
{
  options.services.jellyfin = {
    virtualHost = {
      enable = mkEnableOption "an Nginx virtual host for access to the server";
      fqdn = mkOption {
        description = "FQDN on which to provide the Jellfin server";
        example = "example.org";
        type = lib.types.str;
      };
      tls = {
        enable = mkDisableOption "TLS connections to the Jellyfin server";
        force = mkDisableOption "forcing connections to the server to use TLS";
        acme = mkDisableOption "using ACME to generate TLS certificates for the Jellyfin server";
      };
    };

    requiredSystemdUnits = mkOption {
      description = ''
        Systemd units that are required for Jellyfin to work.  This will
        typically be mount point units.  The Jellyfin systemd service will
        have "BindsTo" and "After" dependencies on units given here.
      '';
      type = lib.types.listOf utils.systemdUtils.lib.unitNameType;
      default = [ ];
      example = [ "usr-local-share-music.mount" ];
    };

    niceness = mkOption {
      description = ''
        Niceness value at which to run the Jellyfin server.
      '';
      type = with lib.types; nullOr (ints.between (-20) 19);
      default = null;
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.jellyfin = {
      bindsTo = cfg.requiredSystemdUnits;
      after = cfg.requiredSystemdUnits;
      serviceConfig.Nice = lib.mkIf (cfg.niceness != null) cfg.niceness;
      wants = lib.mkIf cfg.virtualHost.enable [ "nginx.service" ];
    };

    services.nginx = lib.mkIf cfg.virtualHost.enable {
      enable = true;
      recommendedTlsSettings = lib.mkIf cfg.virtualHost.tls.enable true;
      virtualHosts."${cfg.virtualHost.fqdn}" = {
        locations."/" = {
          proxyPass = "http://127.0.0.1:8096";
          recommendedProxySettings = true;
        };
        enableACME = cfg.virtualHost.tls.acme;
        forceSSL = cfg.virtualHost.tls.force;
      };
    };

    networking.firewall.allowedTCPPorts = lib.mkIf cfg.virtualHost.enable (
      [ 80 ] ++ lib.optional cfg.virtualHost.tls.enable 443
    );

    users.groups."${cfg.group}".members = [ config.users.me ];
  };
}
