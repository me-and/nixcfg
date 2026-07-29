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
  version = "0-unstable-2026-07-29";

  src = fetchFromGitHub {
    owner = "me-and";
    repo = "asmodeus";
    rev = "5f18b4abcdc763060e83a99ae946afeaf5962601";
    hash = "sha256-UuGte0bZZGxw/SFgwa/xLqLAAmok/fbqJZtbVdgQEm0=";
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
