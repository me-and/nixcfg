{ pkgs, personalCfg, ... }:
{
  imports = [ personalCfg.homeModules.latex ];

  home.stateVersion = "25.11";

  home.packages = with pkgs; [
    poppler-utils
    mypkgs.pd-sync-with-fileserver
    mypkgs.unison-nox
  ];

  programs.taskwarrior.backup.enable = true;
}
