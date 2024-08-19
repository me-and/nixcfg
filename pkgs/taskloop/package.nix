{
  bashInteractive,
  coreutils,
  mtimewait,
  toil,
  taskwarrior,
  writeCheckedShellApplication,
}:
writeCheckedShellApplication {
  name = "taskloop";
  runtimeInputs = [
    bashInteractive
    coreutils
    mtimewait
    taskwarrior
    toil
  ];
  text =
    builtins.replaceStrings
    ["~/.local/lib/taskloop/tasklooprc"]
    ["${./tasklooprc}"]
    (builtins.readFile ./taskloop);
}
