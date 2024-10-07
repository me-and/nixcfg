# https://github.com/NixOS/nixpkgs/pull/345993
{
  config,
  lib,
  ...
}: let
  cfg = config.services.openvpn;
in
  lib.mkIf (cfg.servers != {}) {
    systemd.services = lib.optionalAttrs cfg.restartAfterSleep {
      openvpn-restart.script = let
        unitNames = map (n: "openvpn-${n}.service") (builtins.attrNames cfg.servers);
      in
        lib.mkForce "systemctl try-restart ${lib.escapeShellArgs unitNames}";
    };
  }
