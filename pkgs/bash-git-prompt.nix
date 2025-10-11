{
  fetchFromGitHub,
  runCommandLocal,
  python3,
}:
let
  src = fetchFromGitHub {
    owner = "magicmonty";
    repo = "bash-git-prompt";
    tag = "2.7.1";
    hash = "sha256-FWeYzISY4+cS2xg6skfcpTXgbkBs41E/EzEb3JNdFoQ=";
  };
in
runCommandLocal "bash-git-prompt"
  {
    buildInputs = [ python3 ];
  }
  ''
    cp --reflink=auto -pr ${src} $out
    chmod -R u+w $out
    patchShebangs $out
  ''
