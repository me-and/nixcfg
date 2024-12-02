{
  bashInteractive,
  coreutils,
  mtimewait,
  toil,
  taskwarrior2,
  ncurses,
  jq,
  writeCheckedShellApplication,
}:
writeCheckedShellApplication {
  name = "taskloop";
  runtimeInputs = [
    bashInteractive
    coreutils
    mtimewait
    taskwarrior2
    toil
    jq
    ncurses
  ];
  text =
    builtins.replaceStrings
    ["__TASKLOOPRC_PATH__"]
    ["${./tasklooprc}"]
    (builtins.readFile ./taskloop);
}
