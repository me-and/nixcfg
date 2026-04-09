{
  input-mono,
  nerd-font-patcher,
  stdenvNoCC,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "input-mono-nerdfont";
  version = input-mono.version;

  src = input-mono;

  nativeBuildInputs = [ nerd-font-patcher ];

  buildPhase = ''
    runHook preBuild
    for f in share/fonts/truetype/*.ttf; do
      nerd-font-patcher \
        --makegroups 0 \
        --mono \
        --complete \
        "$f"
    done
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    install -Dm444 -t $out/share/fonts/truetype *.ttf
    runHook postInstall
  '';

  meta = {
    inherit (input-mono.meta) license platforms;
  };
})
