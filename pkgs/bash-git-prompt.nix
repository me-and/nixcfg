{
  fetchFromGitHub,
  stdenvNoCC,
  python3,
  nix-update-script,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "bash-git-prompt";
  version = "2.7.1-unstable-2026-11-11";
  src = fetchFromGitHub {
    owner = "magicmonty";
    repo = "bash-git-prompt";
    rev = "8fd8cb066993c3d2e154075743e74c09b8a06065";
    hash = "sha256-QCA5ZWXs9uEhqxgHUTDQ5zz1EPIjy6BJ26ewJ6fCwT4=";
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
