# The set of latex packages I normally want, so I can refer to it as a flake
# package output.
{ texliveMinimal }:
texliveMinimal.withPackages (
  ps: with ps; [
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
)
