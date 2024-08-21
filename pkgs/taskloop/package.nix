{
  bashInteractive,
  coreutils,
  mtimewait,
  toil,
  taskwarrior,
  ncurses,
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
    ncurses
  ];
  text =
    builtins.replaceStrings
    ["__TASKLOOPRC_PATH__"]
    ["${./tasklooprc}"]
    (builtins.readFile ./taskloop);
}
