{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.programs.keepassxc;
in
  lib.mkIf cfg.enable {
    programs.keepassxc.autostart.enable = true;
  }
