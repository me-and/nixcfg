{ pkgs, ... }:
{
  home.stateVersion = "25.11";

  home.packages = with pkgs; [
    azuredatastudio
    discord
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
    "discord"
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
