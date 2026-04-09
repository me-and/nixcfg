{
  fetchFromGitHub,
  stdenvNoCC,
  python3,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "bash-git-prompt";
  version = "2.7.1";
  src = fetchFromGitHub {
    owner = "magicmonty";
    repo = "bash-git-prompt";
    tag = finalAttrs.version;
    hash = "sha256-FWeYzISY4+cS2xg6skfcpTXgbkBs41E/EzEb3JNdFoQ=";
  };
  buildInputs = [ python3 ];
  nativeBuildInputs = [ python3 ];
  installPhase = ''
    runHook preInstall
    cp --reflink=auto -pr ./ $out
    runHook postInstall
  '';
})
