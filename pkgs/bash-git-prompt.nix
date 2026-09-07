{
  fetchFromGitHub,
  stdenvNoCC,
  python3,
  nix-update-script,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "bash-git-prompt";
  version = "2.7.1-unstable-2026-04-10";
  src = fetchFromGitHub {
    owner = "magicmonty";
    repo = "bash-git-prompt";
    rev = "0bca4060a7b43d315e56113c7fb636e03cc29573";
    hash = "sha256-aLaepMTpaagHK/3xCvWdNe9x2eoY1xIsHNhPypC73LA=";
  };
  buildInputs = [ python3 ];
  nativeBuildInputs = [ python3 ];
  installPhase = ''
    runHook preInstall
    cp --reflink=auto -pr ./ $out
    runHook postInstall
  '';

  passthru.updateScript = nix-update-script {
    extraArgs = [
      "--flake"
      "--version"
      "branch"
    ];
  };
})
