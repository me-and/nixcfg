{
  config,
  lib,
  pkgs,
  ...
}:
let
  nginxCfg = config.services.nginx;

  fileSrcPath = "/home/adam/Documents/Gnucash/gnucash.gnucash";
  fileDstPath = "/run/nginx-gnucash/gnucash.gnucash";
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

  systemd.tmpfiles.settings.gnucash-to-nginx = {
    "${builtins.dirOf fileDstPath}" = {
      "d$" = {
        mode = "0750";
        user = "root";
        group = nginxCfg.group;
      };
      Z = {
        mode = "~0750";
        user = "root";
        group = nginxCfg.group;
      };
    };
  };

  systemd.services.gnucash-to-nginx = {
    description = "Move GnuCash file into place for service by Nginx";
    path = [ pkgs.mypkgs.mtimewait ];
    wantedBy = [ "nginx.service" ];
    before = [ "nginx.service" ];
    environment = {
      SOURCE = fileSrcPath;
      DST_DIR = builtins.dirOf fileDstPath;
      DST_NAME = builtins.baseNameOf fileDstPath;
      DST_GROUP = nginxCfg.group;
    };
    script = ''
      umask 0027
      mtimewait 5 "$SOURCE"
      tmpdest="$(mktemp "$DST_DIR"/"$DST_NAME".XXXXX.tmp)"
      cp "$SOURCE" "$tmpdest"
      chown root:"$DST_GROUP" "$tmpdest"
      chmod 640 "$tmpdest"
      mv "$tmpdest" "$DST_DIR"/"$DST_NAME"
    '';
    unitConfig.RequiresMountsFor = [
      "/run"
      fileSrcPath
    ];
    serviceConfig.Type = "oneshot";
  };

  systemd.paths.gnucash-to-nginx = {
    description = "Move GnuCash file into place when it changes";
    wantedBy = [ "nginx.service" ];
    before = [ "nginx.service" ];
    pathConfig.PathChanged = fileSrcPath;
    unitConfig.RequiresMountsFor = [ fileSrcPath ];
  };

  services.nginx = {
    enable = true;
    virtualHosts."${fqdn}" = {
      forceSSL = true;
      basicAuthFile = "/etc/nginx/auth/${fqdn}";
      locations."= /gnucash.gnucash".root = builtins.dirOf fileDstPath;
      enableACME = true;
      acmeRoot = null;
    };
  };
}
