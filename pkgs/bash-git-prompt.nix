{
  fetchFromGitHub,
  stdenvNoCC,
  python3,
  nix-update-script,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "bash-git-prompt";
  version = "2.7.1-unstable-2026-11-05";
  src = fetchFromGitHub {
    owner = "magicmonty";
    repo = "bash-git-prompt";
    rev = "0ea223b51dd0f7db1e7874743261ea78448f9df0";
    hash = "sha256-Yb1I+crGv7y//+yDixWm+OFCLaTBtzsLj8DGe6hFs3Q=";
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
