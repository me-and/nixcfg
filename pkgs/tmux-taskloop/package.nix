{
  lib,
  bashInteractive,
  tmux,
  taskloop,
  writeTextFile,
  writeCheckedShellApplication,
}: let
  tmuxCommands = [
    # Start the session.  We'll have a single session called "taskloop" with a
    # single window with the same name.
    #
    # Lots of examples online use `-d` here to avoit attaching to the session
    # straight away, and instead attach to the session once it is set up.
    # Don't do that here, because that prevents the session knowing the correct
    # size for its windows, and passing that information through seems
    # remarkably complicated.
    #
    # TODO: Ability to have multiple sessions in parallel.
    "new-session -s taskloop -n taskloop -e TMUX_TASKLOOP=Yes"

    # If any pane -- normally the Bash prompt pane -- exits, terminate the
    # entire session.
    "set-hook -w pane-exited kill-session"

    # Create a new pane to the left of the first pane, and launch taskloop in
    # that new pane.
    "split-window -b -h ${bashInteractive}/bin/bash -c 'read; exec ${taskloop}/bin/taskloop -n'"

    # Create a new pane below the previous pane, with the waitingfor taskloop.
    "split-window -v ${bashInteractive}/bin/bash -c 'read; exec ${taskloop}/bin/taskloop -n waitingfor'"

    # Set the panes to resize automatically if the window is resized.  This
    # also seems to be triggered at start of day, which is handy, as it means
    # the config is set automatically!
    #
    # Set the command window to always be 80 columns wide, and set the two
    # taskloop windows to be 50% of their column.
    "set-hook -w window-resized { resize-pane -t %0 -x 80 ; resize-pane -t %1 -y 50% }"

    # Return to the first pane.
    "select-pane -t %0"

    # Disable the prefix keys, since now we're set up I won't need to control
    # tmux from within the session, and would rather any tmux prefix controls
    # are passed through.
    "set-option prefix None"
    "set-option prefix2 None"

    # Disable the status line, because I also don't need that now I have the
    # tmux session started.  Handily, this also triggers the "window-resized"
    # hook to set the panes to the right size.
    "set-option status off"

    # Trigger the two taskloop panes to actually load, now their size is fixed.
    "send-keys -t %1 C-m"
    "send-keys -t %2 C-m"
  ];

  # Use " ; " to join the Tmux commands, since that will mean if an earlier
  # command fails, later commands won't run.
  tmuxCommandFile = writeTextFile {
    name = "tmux-taskloop-conf";
    text = lib.strings.concatStringsSep " ; " tmuxCommands;
  };
in
  writeCheckedShellApplication {
    name = "tmux-taskloop";
    text = ''
      exec ${tmux}/bin/tmux \
          start-server \; \
          source-file ${tmuxCommandFile}
    '';
  }
