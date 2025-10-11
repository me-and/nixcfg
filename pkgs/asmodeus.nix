{
  fetchFromGitHub,
  python3Packages,
}:
let
  inherit (python3Packages) buildPythonPackage dateutil setuptools;
in
buildPythonPackage {
  name = "asmodeus";

  src = fetchFromGitHub {
    owner = "me-and";
    repo = "asmodeus";
    rev = "3355cf49e7382ee9a50a26c89081420372dfdb80";
    hash = "sha256-fdZV1NJGkPvL+P/PWYETKPNj4WOwi7xyeT8/HL5EPnM=";
  };

  pyproject = true;
  nativeBuildInputs = [ setuptools ];

  dependencies = [ dateutil ];
}
