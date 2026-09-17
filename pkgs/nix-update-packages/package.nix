{
  lib,
  inputs,
  runCommand,
  nix-update,
  stdenv,
  shellcheck-minimal,
}:
let
  runtimeInputs = [ nix-update ];

  scriptReplaceArgs = [
    "--replace-fail"
    "import ./updateable-packages.nix"
    "import ${placeholder "out"}/lib/updateable-packages.nix"
    "--replace-fail"
    "export PATH"
    "export PATH=\"\${PATH:+\"$PATH\":}\"${lib.makeBinPath runtimeInputs}"
  ]
  ++ lib.optionals (stdenv.hostPlatform.system != "x86_64-linux") [
    "--replace-fail"
    "declare -r system=x86_64-linux"
    "declare -r system=${lib.escapeShellArg stdenv.hostPlatform.system}"
  ];
in
runCommand "nix-update-packages" { } ''
  mkdir -p -- "$out"/bin
  mkdir -p -- "$out"/lib

  substitute \
      ${./nix-update-packages.sh} "$out"/bin/nix-update-packages \
      ${lib.escapeShellArgs scriptReplaceArgs}
  substitute \
      ${./updateable-packages.nix} "$out"/lib/updateable-packages.nix \
      --replace-fail 'import <nixpkgs/lib>' 'import '${lib.escapeShellArg inputs.nixpkgs}/lib

  chmod +x "$out"/bin/nix-update-packages
  patchShebangs "$out"/bin/nix-update-packages

  ${stdenv.shellDryRun} "$out"/bin/nix-update-packages
  ${lib.getExe shellcheck-minimal} \
      --exclude SC2016 \
      --enable check-extra-masked-returns,check-set-e-suppressed,deprecate-which,require-double-brackets,quote-safe-variables \
      "$out"/bin/nix-update-packages
''
