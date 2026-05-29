{
  fetchFromGitHub,
  python3Packages,
  nix-update-script,
}:
let
  inherit (python3Packages) buildPythonPackage python-dateutil setuptools;
in
buildPythonPackage {
  name = "asmodeus";
  version = "0-unstable-2026-05-28";

  src = fetchFromGitHub {
    owner = "me-and";
    repo = "asmodeus";
    rev = "ce6e2b16f850c3f754ff7c89ee61e07c26619caa";
    hash = "sha256-wztPl0qs9eCQ/+wIQM93DbmTxIbapUAXRoBw7E4Mvg0=";
  };

  pyproject = true;
  nativeBuildInputs = [ setuptools ];

  dependencies = [ python-dateutil ];

  passthru.updateScript = nix-update-script {
    extraArgs = [
      "--flake"
      "--version"
      "branch"
    ];
  };
}
