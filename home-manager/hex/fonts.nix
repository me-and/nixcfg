{ pkgs, ... }:
{
  fonts.fontconfig.enable = true;

  home.packages = with pkgs; [
    privatepkgs.fonts.albertus
    atkinson-hyperlegible-next
    cardo # Free digitisation of Bembo, aka Aldine 401
  ];
}
