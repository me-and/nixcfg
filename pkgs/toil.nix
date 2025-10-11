{
  fetchFromGitHub,
  stdenv,
}:
let
  version = "0.1.1";
in
stdenv.mkDerivation {
  inherit version;
  pname = "toil";
  # This is sufficiently quick to build that it seems wasteful to use a remote
  # builder.
  preferLocalBuild = true;
  src = fetchFromGitHub {
    owner = "me-and";
    repo = "toil";
    rev = "v${version}";
    hash = "sha256-IW/p1H3QteyyU1BkmIpb/U9XrXZjr/+xVy596KNLgPE=";
  };
  makeFlags = [ "prefix=${placeholder "out"}" ];
}
