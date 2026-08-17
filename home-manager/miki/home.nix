{ pkgs, personalCfg, ... }:
{
  imports = [ personalCfg.homeModules.discord ];

  home.stateVersion = "25.11";

  home.packages = with pkgs; [
    azuredatastudio
    gnucash
    hunspell
    hunspellDicts.en-gb-ise
    inkscape
    libreoffice
    openscad
    poppler-utils
    rdfind
    signal-desktop
    telegram-desktop
    tidal-hifi
    zoom-us
  ];

  nixpkgs.config.allowUnfreePackages = [
    "azuredatastudio"
    "castlabs-electron" # For tidal-hifi
    "zoom"
  ];

  programs.firefox.enable = true;
  programs.keepassxc.enable = true;
  programs.zapzap.enable = true;

  services.syncthing = {
    enable = true;
    # TODO Swap this to using the plasmoid version.
    tray.enable = true;
  };
}
