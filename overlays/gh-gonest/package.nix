{
  lib,
  fetchFromGitHub,
  stdenvNoCC,
  makeWrapper,
  bashInteractive,
  gh,
  jq,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "gh-gonest";
  version = "0-unstable-2025-12-17";

  src = fetchFromGitHub {
    owner = "emmanuel-ferdman";
    repo = "gh-gonest";
    rev = "4be041b29e6e102b04b00f98619c818780060a60";
    hash = "sha256-NTqq7y/6Gw1CXgmEpj7an2bT7d5ZFjjlV4zyBthC5yw=";
  };

  strictDeps = true;

  nativeBuildInputs = [
    bashInteractive
    makeWrapper
  ];

  buildInputs = [
    bashInteractive
    gh
    jq
  ];

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    install -D -m755 gh-gonest "$out"/bin/gh-gonest
  '';

  # Use --suffix to ensure that, if the user has a `gh` executable (e.g.
  # because they've set `programs.gh.package` in Home Manager), then that gets
  # picked up first.
  postFixup = ''
    wrapProgram "$out"/bin/gh-gonest \
      --suffix PATH : ${lib.makeBinPath finalAttrs.buildInputs}
  '';
})
