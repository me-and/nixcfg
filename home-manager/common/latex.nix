# TODO Handle the lualatex font cache per
# https://nixos.org/manual/nixpkgs/stable/#sec-language-texlive-lualatex-font-cache
# -- this should probably update if and when the font list changes, if it's
# possible to check and update that in a Home Manager update script.
{
  config,
  lib,
  pkgs,
  ...
}: {
  options.programs.latex.enable = lib.mkEnableOption "LaTeX";

  config = let
    latex = pkgs.texliveMinimal.withPackages (
      ps:
        with ps; [
          babel-english
          collection-basic
          collection-latex
          collection-latexrecommended
          dejavu
          hyphen-english
          lastpage
          latexmk
          nowidow
          nth
          xurl
        ]
    );
  in
    lib.mkIf config.programs.latex.enable {
      home.packages = [latex];
    };
}
