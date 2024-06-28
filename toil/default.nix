{
  fetchFromGitHub,
  stdenv,
}: let
  version = "0.1.1";
in
  stdenv.mkDerivation {
    inherit version;
    pname = "toil";
    src = fetchFromGitHub {
      owner = "me-and";
      repo = "toil";
      rev = "v${version}";
      hash = "sha256-IW/p1H3QteyyU1BkmIpb/U9XrXZjr/+xVy596KNLgPE=";
    };
    makeFlags = ["prefix=/" "DESTDIR=${placeholder "out"}"];
  }
