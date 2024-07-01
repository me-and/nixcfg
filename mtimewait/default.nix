{
  fetchFromGitHub,
  stdenvNoCC,
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
  installPhase = ''
    mkdir -p $out/bin
    cp mtimewait $out/bin/
  '';
}
