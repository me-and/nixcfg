{
  tmux,
  taskloop,
  writeCheckedShellApplication,
}:
writeCheckedShellApplication {
  name = "tmux-taskloop";
  text = ''
    exec ${tmux}/bin/tmux \
        new-session -s taskloop ${taskloop}/bin/taskloop -n \; \
        split-window -v ${taskloop}/bin/taskloop -n waitingfor \; \
        split-window -v -e TMUX_TASKLOOP=Yes
  '';
}
