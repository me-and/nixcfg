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
  version = "0-unstable-2026-08-28";

  src = fetchFromGitHub {
    owner = "me-and";
    repo = "asmodeus";
    rev = "87563088282f15e3affe4f8548cdf5d45357840b";
    hash = "sha256-F7K6KpLH8Dzv97eZT5IwdsIw8p/TDB0Awj8pNnjkd1M=";
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
