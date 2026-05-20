{
  lib,
  fetchFromGitHub,
  stdenvNoCC,
  makeWrapper,
  jq,
}:
stdenvNoCC.mkDerivation {
  pname = "gh-gistsync";
  version = "0-unstable-2026-05-20";
  src = fetchFromGitHub {
    owner = "me-and";
    repo = "gh-gistsync";
    rev = "458c58c42e7cf04bba7e8429360f360031415c08";
    hash = "sha256-qSx9kpCZ3x1CDRr8nRj8vZplqSWgqHgYrh5jVYE9b6Q=";
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
