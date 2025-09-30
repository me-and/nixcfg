{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.gnucashFileServer;
  nginxCfg = config.services.nginx;
in {
  options.services.gnucashFileServer = {
    enable = lib.mkEnableOption "serving my GnuCash file for download by Excel";
    source = lib.mkOption {
      description = "Path to the GnuCash file to serve.";
      type = lib.types.pathWith {
        inStore = false;
        absolute = true;
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
    environment.etc."nginx/auth/${cfg.fqdn}" = {
      user = nginxCfg.user;
      group = nginxCfg.group;
      source = cfg.authFilePath;
      mode = "0640";
    };

    systemd.services.gnucash-to-nginx = {
      description = "Move GnuCash file into place for service by Nginx";
      path = [pkgs.mtimewait];
      wantedBy = ["nginx.service"];
      before = ["nginx.service"];
      environment = {
        SOURCE = cfg.source;
        DST_DIR = "/run/nginx-gnucash";
        DST_NAME = "gnucash.gnucash";
        DST_GROUP = nginxCfg.group;
      };
      script = ''
        mtimewait 5 "$SOURCE"
        mkdir -p "$DST_DIR"
        tmpdest="$(mktemp "$DST_DIR"/"$DST_NAME".XXXXX.tmp)"
        cp "$SOURCE" "$tmpdest"
        chown :"$DST_GROUP" "$tmpdest"
        chmod 640 "$tmpdest"
        mv "$tmpdest" "$DST_DIR"/"$DST_NAME"
      '';
      unitConfig.RequiresMountsFor = [
        "/run"
        cfg.source
      ];
      serviceConfig.Type = "oneshot";
    };

    systemd.paths.gnucash-to-nginx = {
      description = "Move GnuCash file into place when it changes";
      wantedBy = ["nginx.service"];
      before = ["nginx.service"];
      pathConfig.PathChanged = cfg.source;
      unitConfig.RequiresMountsFor = [cfg.source];
    };

    services.nginx = {
      enable = true;
      virtualHosts."${cfg.fqdn}" =
        lib.recursiveUpdate
        {
          forceSSL = true;
          basicAuthFile = "/etc/nginx/auth/${cfg.fqdn}";
          locations."= /gnucash.gnucash" = {
            root = "/run/nginx-gnucash";
          };
        }
        cfg.extraVirtualHostConfig;
    };
  };
}
