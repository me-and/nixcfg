{
  config,
  lib,
  ...
}: let
  cfg = config.services.gnucashFileServer;
  nginxCfg = config.services.nginx;
in {
  options.services.gnucashFileServer = {
    enable = lib.mkEnableOption "serving my GnuCash file for download by Excel";
    rclone = {
      gnucashDirectory = lib.mkOption {
        type = lib.types.str;
        description = "Rclone path to the folder containing the Gnucash file.";
      };
      needsTime = lib.mkOption {
        description = ''
          Whether rclone needs to wait for the system to have synchronised its
          clock before it can mount the unit.

          This is often necessary for remotes that use time-based authentication
          tokens.
        '';
        type = lib.types.bool;
        default = false;
      };
      needsNetwork = lib.mkOption {
        description = ''
          Whether rclone needs to wait for the system to have external network
          connectivity before it can mount the unit.
        '';
        type = lib.types.bool;
        default = true;
      };
    };

    fqdn = lib.mkOption {
      type = lib.types.str;
      description = "FQDN on which to serve the Gnucash file.";
      default = config.networking.fqdn;
    };
    extraVirtualHostConfig = lib.mkOption {
      description = ''
        Configuration to merge into the
        services.nginx.virtualHosts."''${cfg.fqdn}" block.
      '';
      type = lib.types.attrs;
      default = {};
    };
    authFilePath = lib.mkOption {
      description = ''
        Path to the file containing the authentication configuration.  Create
        using `''${pkgs.apacheHttpd}/bin/htpasswd -B <filename> <username>`.
      '';
      type = lib.types.path;
    };
  };

  config = lib.mkIf cfg.enable {
    programs.rclone.mounts = [
      {
        inherit (cfg.rclone) needsTime needsNetwork;
        what = cfg.rclone.gnucashDirectory;
        where = "/run/rclone-nginx-gnucash";
        extraUnitConfig = {
          wantedBy = ["nginx.service"];
          serviceConfig.RuntimeDirectory = "rclone-nginx-gnucash";
        };
        mountOwner = nginxCfg.user;
        readOnly = true;
      }
    ];

    environment.etc."nginx/auth/${cfg.fqdn}" = {
      user = nginxCfg.user;
      group = nginxCfg.group;
      source = cfg.authFilePath;
      mode = "0640";
    };

    services.nginx = {
      enable = true;
      virtualHosts."${cfg.fqdn}" =
        lib.recursiveUpdate
        {
          forceSSL = true;
          basicAuthFile = "/etc/nginx/auth/${cfg.fqdn}";
          locations."= /gnucash.gnucash" = {
            root = "/run/rclone-nginx-gnucash";
          };
        }
        cfg.extraVirtualHostConfig;
    };
  };
}
