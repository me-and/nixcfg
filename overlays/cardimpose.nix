# https://github.com/NixOS/nixpkgs/pull/363750
final: prev:
prev.lib.warnIf (prev.lib.oldestSupportedReleaseIsAtLeast 2505)
''
  Unnecessary definition of cardimpose package in
  ${./.}/cardimpose.nix
''
(
  if builtins.hasAttr "cardimpose" prev
  then {}
  else {
    cardimpose =
      final.callPackage
      ({
        lib,
        python3Packages,
        fetchPypi,
      }:
        python3Packages.buildPythonApplication rec {
          pname = "cardimpose";
          version = "0.2.1";
          pyproject = true;

          src = fetchPypi {
            inherit pname version;
            hash = "sha256-7GyLTUzWd9cZ8/k+0FfzKW3H2rKZ3NHqkZkNmiQ+Tec=";
          };

          build-system = [python3Packages.setuptools];

          dependencies = [python3Packages.pymupdf];
        });
  }
)
