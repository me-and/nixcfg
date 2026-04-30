{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.mosh;
in
{
  options.programs.mosh.portRange = lib.mkOption {
    type = lib.types.nullOr (lib.types.attrsOf lib.types.port);
    default = null;
    example = {
      from = 60000;
      to = 60019;
    };
  };

  config = lib.mkMerge [
    (lib.mkIf (cfg.portRange != null) {
      # Don't use the default port configuration.
      programs.mosh.openFirewall = false;

      networking.firewall.allowedUDPPortRanges = [ cfg.portRange ];
    })

    {
      programs.mosh.package = pkgs.mypkgs.mosh;

      # https://github.com/NixOS/nixpkgs/pull/515070
      environment.sessionVariables = {
        MOSH_SERVER_NETWORK_TMOUT = 60 * 60;
        MOSH_SERVER_SIGNAL_TMOUT = 60;
      };
    }
  ];
}
