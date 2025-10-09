# TODO Run shellcheck over the Bash scripts
{
  lib,
  bashInteractive,
  coreutils,
  mtimewait,
  ncurses,
  taskwarrior2,
  tmux,
  toil,
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
  installPhase = let
    taskloopPath = lib.makeBinPath [
      bashInteractive
      coreutils
      mtimewait
      taskwarrior2
      toil
      ncurses
    ];
  in ''
    mkdir -p $out/bin $out/lib $out/libexec

    cp taskloop $out/libexec
    substituteInPlace $out/libexec/taskloop \
        --replace-fail \
            '@@PATH@@' \
            ${lib.escapeShellArg taskloopPath}

    cp tmux-taskloop $out/bin
    substituteInPlace $out/bin/tmux-taskloop \
        --replace-fail \
            'source-file tmux-taskloop.conf' \
            "source-file $out/lib/tmux-taskloop.conf" \
        --replace-fail \
            '@@TMUX@@' \
            '${tmux}/bin/tmux' \
        --replace-fail \
            '@@RM@@' \
            '${coreutils}/bin/rm' \
        --replace-fail \
            '@@MKTEMP@@' \
            '${coreutils}/bin/mktemp'


    cp *.conf $out/lib
    substituteInPlace $out/lib/tmux-taskloop.conf \
        --replace-fail /usr/bin/bash ${bashInteractive}/bin/bash \
        --replace-fail \
            'source-file tmux-taskloop-resize.conf' \
            "source-file $out/lib/tmux-taskloop-resize.conf" \
        --replace-fail \
            '@@TASKLOOP@@' \
            "$out/libexec/taskloop"
  '';
}
