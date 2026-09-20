{
  fetchFromGitHub,
  stdenvNoCC,
  python3,
  nix-update-script,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "bash-git-prompt";
  version = "2.7.1-unstable-2026-09-17";
  src = fetchFromGitHub {
    owner = "magicmonty";
    repo = "bash-git-prompt";
    rev = "450174627cb479d918b4b8c8257de00a2b98b425";
    hash = "sha256-ioXBL42MjuZQlHczv2iBAoCeQdbC5Bs7sYUV9bNfQyU=";
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
