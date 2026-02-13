{
  lib,
  nix-output-monitor,
  runCommand,
  symlinkJoin,
  writeCheckedShellApplication,
}:
let
  nom = writeCheckedShellApplication {
    name = "nom";
    text = ''
      if (( $# >= 2 )) && [[ "$1" = flake && "$2" = check ]]; then
          shift 2
          nix flake check --log-format internal-json -v "$@" |& ${lib.getExe nix-output-monitor} --json
      else
          exec ${lib.getExe nix-output-monitor} "$@"
      fi
    '';
  };

  # nix-output-monitor has other executables that are just symlinks to the
  # `nom` in their local directory, and presumably alter their behaviour based
  # on the executable name.  My `nom` can't handle that, but `symlinkJoin` will
  # propagate this behaviour.  Avoid that by explicitly linking to the correct
  # targets.
  nomWrappers = runCommand "nom-wrappers" { } ''
    mkdir -p "$out"/bin
    cd ${nix-output-monitor}/bin
    for target in *; do
        if [[ "$target" != nom ]]; then
            ln -s ${nix-output-monitor}/bin/"$target" "$out"/bin/"$target"
        fi
    done
  '';
in
symlinkJoin {
  name = "nom";
  paths = [
    nom
    nomWrappers
    nix-output-monitor
  ];
}
