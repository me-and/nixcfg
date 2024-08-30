{
  bashInteractive,
  coreutils,
  mtimewait,
  toil,
  taskwarrior,
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
    taskwarrior
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
