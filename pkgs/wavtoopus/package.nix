{
  lib,
  runtimeShell,
  coreutils,
  opusTools,
  substCheckedShellApplication,
}:
substCheckedShellApplication {
  name = "wavtoopus";
  src = ./wavtoopus.sh;
  substitutions = {
    inherit runtimeShell;
    PATH = lib.makeBinPath [coreutils opusTools];
  };
}
