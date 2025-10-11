{
  lib,
  substCheckedShellApplication,
  runtimeShell,
  less,
  jq,
}:
substCheckedShellApplication {
  name = "task-project-report";
  src = ./task-project-report.sh;
  substitutions = {
    inherit runtimeShell;
    # Don't specify a taskwarrior package: if the user is calling this they
    # presumably have one in their path already, and who knows whether it's v2,
    # v3, or something else entirely...
    PATH = lib.makeBinPath [
      less
      jq
    ];
    script = "${./task-project-report.jq}";
  };
}
