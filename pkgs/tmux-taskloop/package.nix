{
  lib,
  bashInteractive,
  tmux,
  taskloop,
  stdenvNoCC,
  makeBinaryWrapper,
}:
stdenvNoCC.mkDerivation {
  pname = "tmux-taskloop";
  version = "0.1.0";
  src = ./.;
  buildInputs = [
    bashInteractive
    makeBinaryWrapper
  ];
  preferLocalBuild = true;
  installPhase = ''
    mkdir -p $out/bin $out/lib

    cp tmux-taskloop $out/bin
    substituteInPlace $out/bin/tmux-taskloop \
        --replace-fail \
            'source-file tmux-taskloop.conf' \
            "source-file $out/lib/tmux-taskloop.conf"
    wrapProgram $out/bin/tmux-taskloop \
        --prefix PATH : ${lib.makeBinPath [taskloop tmux]}

    cp *.conf $out/lib
    substituteInPlace $out/lib/tmux-taskloop.conf \
        --replace-fail /usr/bin/bash ${bashInteractive}/bin/bash \
        --replace-fail \
            'source-file tmux-taskloop-resize.conf' \
            "source-file $out/lib/tmux-taskloop-resize.conf"
  '';
}
