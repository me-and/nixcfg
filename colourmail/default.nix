{
  fetchFromGitHub,
  stdenvNoCC,
}: let
  version = "1.0.0";
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
    installPhase = ''
      mkdir -p $out/bin
      cp colourmail $out/bin/
    '';
  }
