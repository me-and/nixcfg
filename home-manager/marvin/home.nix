{ pkgs, personalCfg, ... }:
{
  imports = [ personalCfg.homeModules.latex ];

  home.stateVersion = "25.11";

  home.packages = [
    pkgs.mypkgs.wavtoopus
    pkgs.quodlibet-without-gst-plugins # operon
  ];
}
