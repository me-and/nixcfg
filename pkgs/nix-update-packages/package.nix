{
  lib,
  inputs,
  runCommand,
  nix-update,
  stdenv,
}:
let
  runtimeInputs = [ nix-update ];
in
runCommand "nix-update-packages" { } ''
  mkdir -p -- "$out"/bin
  mkdir -p -- "$out"/lib

  substitute \
      ${./nix-update-packages.sh} "$out"/bin/nix-update-packages \
      --replace-fail 'import ./updateable-packages.nix' "import $out/lib/updateable-packages.nix" \
      --replace-fail 'export PATH' 'export PATH="''${PATH:+"$PATH":}"${lib.makeBinPath runtimeInputs}'

  if [[ ${lib.escapeShellArg stdenv.hostPlatform.system} != 'x86_64-linux' ]]; then
      substituteInPlace "$out"/bin/nix-update-packages \
          --replace-fail 'x86_64-linux' ${lib.escapeShellArg stdenv.hostPlatform.system}
  fi

  substitute \
      ${./updateable-packages.nix} "$out"/lib/updateable-packages.nix \
      --replace-fail 'import <nixpkgs/lib>' 'import '${lib.escapeShellArg inputs.nixpkgs}/lib

  chmod +x "$out"/bin/nix-update-packages
  patchShebangs "$out"/bin/nix-update-packages
''
