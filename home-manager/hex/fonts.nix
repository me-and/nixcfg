{ pkgs, ... }:
{
  fonts.fontconfig.enable = true;

  home.packages = with pkgs; [
    privatepkgs.albertus-fonts
    atkinson-hyperlegible-next
    cardo # Free digitisation of Bembo, aka Aldine 401
  ];
}
