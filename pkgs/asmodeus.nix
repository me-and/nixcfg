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
    rev = "2990f0a201b85c97ce45908752e568746143c910";
    hash = "sha256-YeKws3LutRhoAUWVrcctrf5Km83h92WzSpBEwSMf/1E=";
  };

  pyproject = true;
  nativeBuildInputs = [ setuptools ];

  dependencies = [ python-dateutil ];
}
