{
  fetchFromGitHub,
  stdenvNoCC,
}:
stdenvNoCC.mkDerivation {
  pname = "mtimewait";
  version = "2024.06.28";
  src = fetchFromGitHub {
    owner = "me-and";
    repo = "mtimewait";
    rev = "HEAD";
    hash = "sha256-rfoeOVjZ8vt+G5DoQ0KjJJuGgrk+aRjCsuuQYlkY3w8=";
  };
  installPhase = ''
    mkdir -p $out/bin
    cp mtimewait $out/bin/
  '';
}
