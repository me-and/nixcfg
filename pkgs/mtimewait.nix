{
  lib,
  fetchFromGitHub,
  stdenvNoCC,
  makeWrapper,
  coreutils,
}:
stdenvNoCC.mkDerivation rec {
  pname = "mtimewait";
  version = "1.0.0";
  src = fetchFromGitHub {
    owner = "me-and";
    repo = "mtimewait";
    rev = "v${version}";
    hash = "sha256-7usTM6pKv6toLs61RGVtOHC4Yzh1YIgqFclA265vmtg=";
  };
  preferLocalBuild = true;
  nativeBuildInputs = [ makeWrapper ];
  installPhase = ''
    mkdir -p $out/bin
    cp mtimewait $out/bin/mtimewait
    wrapProgram $out/bin/mtimewait \
        --set PATH ${lib.makeBinPath [ coreutils ]}
  '';
}
