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
    ["~/.local/lib/taskloop/tasklooprc"]
    ["${./tasklooprc}"]
    (builtins.readFile ./taskloop);
}
