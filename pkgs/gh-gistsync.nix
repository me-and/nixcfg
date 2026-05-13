{
  lib,
  fetchFromGitHub,
  stdenvNoCC,
  makeWrapper,
  jq,
}:
stdenvNoCC.mkDerivation {
  pname = "gh-gistsync";
  version = "0-unstable-2026-05-13";
  src = fetchFromGitHub {
    owner = "me-and";
    repo = "gh-gistsync";
    rev = "bb9c616c34ab32d130359ca01664948d6bdfad0e";
    hash = "sha256-DdXaTLSaBPA5qr+J3pK6SCmNzHE04tuXNSXwuIHtXTY=";
  };
  preferLocalBuild = true;
  nativeBuildInputs = [ makeWrapper ];
  installPhase = ''
    mkdir -p "$out"/bin
    cp gh-gistsync "$out"/bin/gh-gistsync
    wrapProgram "$out"/bin/gh-gistsync \
        --suffix PATH : ${lib.makeBinPath [ jq ]}
  '';
}
