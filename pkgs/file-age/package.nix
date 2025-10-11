{
  lib,
  runtimeShell,
  coreutils,
  substCheckedShellApplication,
}:
substCheckedShellApplication {
  name = "file-age";
  src = ./file-age.sh;
  substitutions = {
    inherit runtimeShell;
    PATH = lib.makeBinPath [ coreutils ];
  };
}
