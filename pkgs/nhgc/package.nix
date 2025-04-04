# https://github.com/NixOS/nixpkgs/pull/386861
{
  lib,
  fetchFromGitHub,
  nix,
  boost,
  python3Packages,
}:
python3Packages.buildPythonPackage rec {
  pname = "nix-heuristic-gc";
  version = "0.6.0";
  src = fetchFromGitHub {
    owner = "risicle";
    repo = "nix-heuristic-gc";
    rev = version;
    hash = "sha256-lph+rm8qXoA6h2dJTYeuj9HJAx6PnKZSdsKBElbBUbY=";
  };
  NIX_SYSTEM = nix.stdenv.hostPlatform.system;
  NIX_CFLAGS_COMPILE = ["-I${lib.getDev nix}/include/nix"];
  buildInputs = [
    boost
    nix
    python3Packages.pybind11
    python3Packages.setuptools
  ];
  propagatedBuildInputs = [
    python3Packages.humanfriendly
    python3Packages.rustworkx
  ];
  checkInputs = [
    python3Packages.pytestCheckHook
  ];
  preCheck = "mv nix_heuristic_gc .nix_heuristic_gc";
}
