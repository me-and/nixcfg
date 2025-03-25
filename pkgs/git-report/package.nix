{
  lib,
  substCheckedShellApplication,
  runtimeShell,
  gnugrep,
  gnused,
  coreutils,
  moreutils,
  git,
}:
substCheckedShellApplication {
  name = "git-report";
  src = ./git-report.sh;
  substitutions = {
    inherit runtimeShell;
    PATH = lib.makeBinPath [
      coreutils
      gnugrep
      gnused
      moreutils
      git
    ];
  };
}
