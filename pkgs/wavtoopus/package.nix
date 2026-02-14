{
  lib,
  runtimeShell,
  coreutils,
  opus-tools,
  substCheckedShellApplication,
}:
substCheckedShellApplication {
  name = "wavtoopus";
  src = ./wavtoopus.sh;
  substitutions = {
    inherit runtimeShell;
    PATH = lib.makeBinPath [
      coreutils
      opus-tools
    ];
  };
}
