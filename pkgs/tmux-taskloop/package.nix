{
  lib,
  bashInteractive,
  tmux,
  taskloop,
  coreutils,
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
      set-environment -h pane_state 'all separate'

      # Disable the status line and prefix keys, so any inner/outer tmux window
      # works normally.
      %if "#{TMUX_TASKLOOP_DEBUG}"
          display-message "Debug: leaving status line and prefix in place"
      %else
          set-option status off
          set-option prefix none
          set-option prefix2 none
      %endif

      # Set up the window layout for the current window size.
      source-file ${tmuxResizeConf}

      # Set hooks to exit when the command prompt exits, and to resize when the
      # window resizes.
      set-hook -g pane-exited kill-session
      set-hook -g window-resized 'source-file ${tmuxResizeConf}'
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
      %if "#{##:#{pane_state},all in one}"
          break-pane -d -s %1 -n taskloop-next
          break-pane -d -s %2 -n taskloop-waitingfor
      %elif "#{!=:#{pane_state,all separate}"
          display-message -d0 "Unexpected pane state #{pane_state}"
      %endif

      %if "#{e|>:#{window_width},160}"
          # Pull in the panes from the taskloop-next and taskloop-waitingfor
          # windows.  Arrange them one on top of another on the left, with the
          # prompt window on the right and 80 columns wide.
          join-pane -b -h -s =taskloop:taskloop-next -t %0
          join-pane -v -s =taskloop:taskloop-waitingfor -t %1
          resize-pane -t %0 -x 80
          select-pane -t %0

          set-environment -h pane_state 'all in one'

          # Send Return to the two report windows, to trigger them to redraw or
          # run the initial report.
          send-keys -t %1 C-m
          send-keys -t %2 C-m
      %else
          display-message -d0 "Cannot handle a #{window_width}x#{window_height} window"
      %endif
    '';
  };
in
  writeCheckedShellApplication {
    name = "tmux-taskloop";
    runtimeInputs = [coreutils];
    text = ''
      while (( $# > 0 )); do
          case "$1" in
          -d|--debug)
              export TMUX_TASKLOOP_DEBUG=Yes
              shift
              ;;
          *)  echo "Unexpected argument $1" >&2
              exit 64  # EX_USAGE
              ;;
          esac
      done

      exec ${tmux}/bin/tmux \
          -L tmux-taskloop-$$ \
          start-server \; \
          source-file ${tmuxStartupConf}
    '';
  }
