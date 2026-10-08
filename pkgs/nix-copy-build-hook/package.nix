{
  lib,
  substCheckedShellApplication,
  symlinkJoin,
  bash,
  nix,
  coreutils,
  findutils,
  openssh,
}:
let
hook = substCheckedShellApplication {
  name = "nix-copy-post-build-hook";
  src = ./nix-copy-post-build-hook.sh;
  substitutions = {
    BASH = lib.getExe bash;
    PATH = lib.makeBinPath [ nix coreutils findutils ];
  };
};
script = substCheckedShellApplication {
  name = "nix-copy-from-build-hook";
  src = ./nix-copy-from-build-hook.sh;
  substitutions = {
    BASH = lib.getExe bash;
    PATH = lib.makeBinPath [ nix coreutils openssh ];
  };
};
in
  symlinkJoin {
    name = "nix-copy-build-hook";
    paths = [ hook script ];
  }
