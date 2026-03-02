{
  fetchFromGitHub,
  python3Packages,
}:
let
  inherit (python3Packages) buildPythonPackage python-dateutil setuptools;
in
buildPythonPackage {
  name = "asmodeus";

  src = fetchFromGitHub {
    owner = "me-and";
    repo = "asmodeus";
    rev = "38ee7142ee08c05ad98e9c297f9e185a5127eea0";
    hash = "sha256-ZOcVtxzZ1wg/kcoVS961r28HQzEJbswBHClShQiCOd8=";
  };

  pyproject = true;
  nativeBuildInputs = [ setuptools ];

  dependencies = [ python-dateutil ];
}
