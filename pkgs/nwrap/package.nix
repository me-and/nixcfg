{
  lib,
  substCheckedShellApplication,
  runtimeShell,
  nix-copy-builds,
}:
substCheckedShellApplication {
  name = "nwrap";
  src = ./nwrap.sh;
  substitutions = {
    inherit runtimeShell;
    POST-BUILD-HOOK = lib.escapeShellArg "${nix-copy-builds}/bin/nix-copy-build-hook";
  };
}
