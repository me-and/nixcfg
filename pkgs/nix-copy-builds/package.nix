{
  lib,
  substCheckedShellApplication,
  symlinkJoin,
  bash,
  nix,
  coreutils,
  findutils,
  jq,
  openssh,
}:
let
  hook = substCheckedShellApplication {
    name = "nix-copy-build-hook";
    src = ./build-hook.sh;
    substitutions = {
      BASH = lib.getExe bash;
      PATH = lib.makeBinPath [
        nix
        coreutils
        findutils
        jq
      ];
      FILTERJQ = ./filter.jq;
    };
  };
  script = substCheckedShellApplication {
    name = "nix-copy-from-build";
    src = ./nix-copy-from-build.sh;
    substitutions = {
      BASH = lib.getExe bash;
      PATH = lib.makeBinPath [
        nix
        coreutils
        openssh
      ];
    };
  };
in
symlinkJoin {
  name = "nix-copy-build-hook";
  paths = [
    hook
    script
  ];
}
