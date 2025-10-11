{
  lib,
  fetchFromGitHub,
  stdenvNoCC,
  makeWrapper,
  coreutils,
  jq,
  curl,
  gnused,
}:
stdenvNoCC.mkDerivation {
  name = "aaisp-quota";
  src = fetchFromGitHub {
    owner = "me-and";
    repo = "aaisp-quota";
    rev = "88acaf80d522befef969bbf0a4eed5881ccd95fa";
    hash = "sha256-DfKGIgb4OR528bebyaqhacqXpeANpIiSVH+98v1hHuM=";
  };
  preferLocalBuild = true;
  nativeBuildInputs = [ makeWrapper ];
  installPhase = ''
    mkdir -p $out/bin
    cp aaisp-quota month-left $out/bin
    wrapProgram $out/bin/aaisp-quota \
        --set PATH ${
          lib.makeBinPath [
            coreutils
            jq
            curl
          ]
        }
    wrapProgram $out/bin/month-left \
        --set PATH ${
          lib.makeBinPath [
            coreutils
            gnused
          ]
        }
  '';
}
