{
  lib,
  bashInteractive,
  tmux,
  taskloop,
  writeTextFile,
  writeCheckedShellApplication,
}: let
  tmuxStartupConf = writeTextFile {
    name = "tmux-taskloop.conf";
    text = ''
      # Start the prompts we want to keep around.
      new-session -s taskloop -n taskloop -e TMUX_TASKLOOP=Yes
      new-window -d -n taskloop-next ${bashInteractive}/bin/bash -c 'read; exec ${taskloop}/bin/taskloop -ns'
      new-window -d -n taskloop-waitingfor ${bashInteractive}/bin/bash -c 'read; exec ${taskloop}/bin/taskloop -ns waitingfor'

      # Disable the status line and prefix keys, so any inner/outer tmux window
      # works normally.
      set-option status off
      set-option prefix None
      set-option prefix2 None

      # Set up the window layout for the current window size.
      source-file ${tmuxResizeConf}

      # Set hooks to exit when the command prompt exits, and to resize when the
      # window resizes.
      set-hook -w pane-exited kill-session
      set-hook -w window-resized {
          break-pane -d -s %1 -n taskloop-next
          break-pane -d -s %2 -n taskloop-waitingfor
          source-file ${tmuxResizeConf}
      }
    '';
  };

  # This needs to be a separate file, as otherwise tmux seems to parse the
  # `%if` conditionals when it first reads the config file, which means that
  # calling a hook after a resize won't be very useful, as the behaviour will
  # be fixed by the state of the window when the hook was configured, rather
  # than when the hook is run.
  tmuxResizeConf = writeTextFile {
    name = "tmux-taskloop-resize.conf";
    text = ''
      %if "#{e|>:#{window_width},160}"
          # Pull in the panes from the taskloop-next and taskloop-waitingfor
          # windows.  Arrange them one on top of another on the left, with the
          # prompt window on the right and 80 columns wide.
          join-pane -b -h -s =taskloop:taskloop-next -t %0
          join-pane -v -s =taskloop:taskloop-waitingfor -t %1
          resize-pane -t %0 -x 80
          select-pane -t %0

          # Send Return to the two report windows, to trigger them to redraw or
          # run the initial report.
          send-keys -t %1 C-m
          send-keys -t %2 C-m
      %else
          # Turn on the status line so the message is visible, then show a
          # warning.
          set-option status on
          display-message -d0 "Don't know how to handle a #{window_width}x#{window_height} window!"
          set-option status off
      %endif
    '';
  };
in
  writeCheckedShellApplication {
    name = "tmux-taskloop";
    text = ''
      exec ${tmux}/bin/tmux \
          start-server \; \
          source-file ${tmuxStartupConf}
    '';
  }
