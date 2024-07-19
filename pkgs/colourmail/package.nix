{
  lib,
  colorized-logs,
  mailutils,
  perlPackages,
  fetchFromGitHub,
  stdenvNoCC,
  makeWrapper,
}: let
  version = "1.0.0";
  runtimeDeps = [perlPackages.mimeConstruct colorized-logs mailutils];
in
  stdenvNoCC.mkDerivation {
    pname = "colourmail";
    inherit version;
    src = fetchFromGitHub {
      owner = "me-and";
      repo = "colourmail";
      rev = "v${version}";
      hash = "sha256-ruQTeCwObqNKPRyDB7FRTdvbtnaI1f1PX/93wKumoNY=";
    };
    nativeBuildInputs = [makeWrapper];
    installPhase = ''
      mkdir -p $out/bin
      cp colourmail $out/bin/
      wrapProgram $out/bin/colourmail \
          --prefix PATH : ${lib.makeBinPath runtimeDeps}
    '';
  }
