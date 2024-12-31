# https://github.com/NixOS/nixpkgs/pull/369509
{
  config,
  lib,
  ...
}: let
  cfg = config.services.taskserver;
in
  lib.mkIf cfg.enable {
    systemd.services.taskserver-init.preStart = lib.mkForce "";
    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir} 0770 ${cfg.user} ${cfg.group}"
      "z ${cfg.dataDir} 0770 ${cfg.user} ${cfg.group}"
    ];
  }
