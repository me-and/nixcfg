{
  config,
  lib,
  pkgs,
  ...
}:
let
  nginxCfg = config.services.nginx;

  filePath = "/home/adam/Documents/Gnucash/gnucash.gnucash";
  fqdn = config.networking.fqdn;
in
{
  sops.secrets."${fqdn}-auth" = { };

  environment.etc."nginx/auth/${fqdn}" = {
    user = nginxCfg.user;
    group = nginxCfg.group;
    source = config.sops.secrets."${fqdn}-auth".path;
    mode = "0640";
  };

  systemd.services.gnucash-to-nginx = {
    description = "Move GnuCash file into place for service by Nginx";
    path = [ pkgs.mypkgs.mtimewait ];
    wantedBy = [ "nginx.service" ];
    before = [ "nginx.service" ];
    environment = {
      SOURCE = filePath;
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
      filePath
    ];
    serviceConfig.Type = "oneshot";
  };

  systemd.paths.gnucash-to-nginx = {
    description = "Move GnuCash file into place when it changes";
    wantedBy = [ "nginx.service" ];
    before = [ "nginx.service" ];
    pathConfig.PathChanged = filePath;
    unitConfig.RequiresMountsFor = [ filePath ];
  };

  services.nginx = {
    enable = true;
    virtualHosts."${fqdn}" = {
      forceSSL = true;
      basicAuthFile = "/etc/nginx/auth/${fqdn}";
      locations."= /gnucash.gnucash".root = "/run/nginx-gnucash";
      enableACME = true;
      acmeRoot = null;
    };
  };
}
