{ pkgs, personalCfg, ... }:
{
  imports = [ personalCfg.homeModules.latex ];

  home.stateVersion = "25.11";

  home.packages = with pkgs; [ poppler-utils ] ++ (with pkgs.mypkgs; [ unison-nox ]);

  programs.taskwarrior.backup.enable = true;
}
