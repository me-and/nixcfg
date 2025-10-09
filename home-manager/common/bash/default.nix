{lib, ...}: {
  home.file =
    # TODO Move these files into Home Manager more competently; this directory
    # was just a lift-and-shift from my Homeshick castle.
    #
    # Handle each file separately, rather than just linking the entire
    # directory, so that it's possible for other Home Manager config to add
    # files as well.
    (lib.mapAttrs'
      (name: value:
        lib.nameValuePair ".bashrc.d/${name}" {source = ./bashrc.d + "/${name}";})
      (builtins.readDir ./bashrc.d))
    // {
      # This gets sourced automatically if Bash completion is enabled.
      # TODO Move this config into Home Manager more competently, or just retire it
      # because I no longer use Homeshick.
      ".bash_completion".text = ''
        if [[ -d ~/.bash_completion.d &&
              -r ~/.bash_completion.d &&
              -x ~/.bash_completion.d ]]; then
            for file in ~/.bash_completion.d/*; do
                if [[ -f "$file" && -r "$file" ]]; then
                    . "$file"
                fi
            done
        fi
      '';
    };

  programs.bash = {
    enable = true;

    historyControl = ["ignoreboth"];

    shellAliases = {
      # Use colour.
      ls = "ls --color=auto -hv";
      grep = "grep --color=auto";

      # When calling cscope, I generally want some useful default arguments: -k
      # ignores the standard include directories (I'm rarely interested in those
      # anyway), -R recurses into directories, -q builds a reverse-lookup indices for
      # speed, and -b stops cscope launching its interactive mode (why would I want
      # that when I can launch vim directly!?).
      cscope = "cscope -kRqb";

      # https://twitter.com/chris__martin/status/420992421673988096
      such = "git";
      very = "git";
      wow = "git status";

      fucking = "sudo";

      snarf = "aria2c -x16 -s16";

      ag = "ag --hidden --ignore=.git";
    };

    # TODO Handle these paths in a more Nix-friendly fashion, and/or without
    # using any Bashisms, since this is going in .profile rather than
    # .bash_profile.
    profileExtra = ''
      if [[ -e /proc/sys/fs/binfmt_misc/WSLInterop || -e /proc/sys/fs/binfmt_misc/WSLInterop-late ]]; then
              # If BROWSER hasn't already been set somehow, check wslview is available,
              # and set BROWSER to delegate to that.
              if [[ ! -v BROWSER ]] && command -v wslview >/dev/null; then
                      export BROWSER=wslview
              fi
      fi
    '';

    initExtra = ''
      # Function for neater wrapping of messages various.  Use with a here document
      # or here string.
      : "''${MAX_MESSAGE_WIDTH:=79}"
      if command -v fmt >/dev/null; then
              wrap_message () {
                      if [[ -t 0 ]]; then
                              wrap_message <<<'wrap_message has a terminal on stdin, did you miss a redirect?'
                              return 1
                      fi
                      local -i target_width screen_width
                      screen_width="''${COLUMNS:-79}"
                      target_width="$((screen_width>MAX_MESSAGE_WIDTH ? MAX_MESSAGE_WIDTH : screen_width))"
                      fmt -cuw"$target_width"
              }
      else
              wrap_message () {
                      if [[ -t 0 ]]; then
                              wrap_message <<<'wrap_message has a terminal on stdin, did you miss a redirect?'
                              return 1
                      fi
                      cat
              }
              wrap_message <<<'fmt unavailable' >&2
      fi

      # Function for truncating a message so it fits on one line.
      cut_message () {
              if (( "''${#1}" > COLUMNS )); then
                      printf '%s\n' "''${1::COLUMNS-3}..."
              else
                      printf '%s\n' "$1"
              fi
      }

      # Utility function to make tracing other Bash functions easier.
      tracewrap () {
              local -
              set -x
              "$@"
      }

      # Simple random number generator.
      rand () {
              local -i lo hi range
              case "$#" in
                      1)	lo=1
                              hi="$1"
                              ;;
                      2)	lo="$1"
                              hi="$2"
                              ;;
                      *)	wrap_message >&2 <<'EOF'
      Specify either `rand <lo> <hi>` to choose a number between <lo>
      and <hi>, or `rand <hi>` to choose a number between 1 and <hi>.
      EOF
                              return 64  # EX_USAGE
                              ;;
              esac
              (( range = hi - lo + 1 ))
              echo $(( (SRANDOM % range) + lo ))
      }
      rand_ephemeral_port () { rand 49152 65535; }

      set_terminal_title () {
              echo -ne '\e]0;'"$*"'\a'
      }

      if command -v gh >/dev/null && [[ "$BASH_COMPLETION_VERSINFO" ]]; then
              # Use gh completion.
              eval "$(gh completion -s bash)"
      fi

      # bashwrap function: given a function name and code to run before and/or after,
      # wrap the existing function with the code that comes before and after.  The
      # before and after code is taken literally and eval'd, so it can do things like
      # access "$@" and indeed change "$@" by using shift or set or similar.
      bashwrap () {
              local command beforecode aftercode type unset_extglob n
              local innerfuncname innerfunccode
              local -n varname

              command="$1"
              beforecode="$2"
              aftercode="$3"

              # Check the current state of extglob: this code needs it to be set,
              # but it should be reset to avoid unexpected changes to the global
              # envirnoment.
              if ! shopt -q extglob; then
                      unset_extglob=YesPlease
                      shopt -s extglob
              fi

              # Tidy the before and after code: trim whitespace from the start and end,
              # and make sure they end with a single semicolon.
              for varname in beforecode aftercode; do
                      varname="''${varname##+([$'\n\t '])}"
                      varname="''${varname%%+([$'\n\t '])}"
                      if [[ "$varname" ]]; then
                              varname="''${varname%%+(;)};"
                      fi
              done

              # Now finished with extglob.
              if [[ "$unset_extglob" ]]; then shopt -u extglob; fi

              type="$(type -t "$command")"
              case "$type" in
                      alias)
                              wrap_message <<<"bashwrap doesn't (yet) know how to handle aliases" >&2
                              return 69  # EX_UNAVAILABLE
                              ;;
                      keyword)
                              wrap_message <<<'bashwrap cannot wrap Bash keywords' >&2
                              return 64  # EX_USAGE
                              ;;
                      builtin|file)
                              eval "$command () { $beforecode command $command \"\$@\"; $aftercode }"
                              ;;
                      function)
                              # Keep generating function names until we get to one that doesn't
                              # exist.  This allows a function to be wrapped multiple times; the
                              # original function will always have the name
                              # _bashwrapped_0_<name>.
                              n=0
                              innerfuncname="_bashwrapped_''${n}_$command"
                              while declare -Fp -- "$innerfuncname" &>/dev/null; do
                                      innerfuncname="_bashwrapped_$((++n))_$command"
                              done

                              # Define a new function with the new function name and the old function
                              # code.
                              innerfunccode="$(declare -fp -- "$command")"
                              eval "''${innerfunccode/#$command /$innerfuncname }"

                              # Redefine the existing function to call the new function, in
                              # between the wrapper code.
                              eval "$command () { $beforecode $innerfuncname \"\$@\"; $aftercode }"
                              ;;
                      "")
                              wrap_message <<<"Nothing called ''${command@Q} found to wrap" >&2
                              return 64  # EX_USAGE
                              ;;
                      *)
                              wrap_message <<<"Unexpected object type $type" >&2
                              return 70  # EX_SOFTWARE
                              ;;
              esac
      }

      # Wrapper to provide an editor function that will work even if the executable
      # doesn't exist.
      editor () {
              local cmd

              for cmd in "$VISUAL" "$EDITOR"; do
                      if [[ "$cmd" ]]; then
                              if [[ "$cmd" = editor ]]; then
                                      # Handle `editor` specially, as otherwise we get infinite
                                      # recursion into this function.
                                      command editor "$@"
                              else
                                      "$cmd" "$@"
                              fi
                              return "$?"
                      fi
              done

              if command -v editor >/dev/null; then
                      # There's an editor executable, so use that.
                      command editor "$@"
                      return "$?"
              fi

              for cmd in vim vi nano pico; do
                      if type -t "$cmd" >/dev/null; then
                              "$cmd" "$@"
                              return "$?"
                      fi
              done

              # If we get to this point, we haven't found any editor to run!
              wrap_message <<<'No editor found!' >&2
              return 127
      }

      # Import local .bashrc files if they exist.
      if [[ -d ~/.bashrc.d && -r ~/.bashrc.d && -x ~/.bashrc.d ]]; then
              for file in ~/.bashrc.d/*; do
                      if [[ -f "$file" && -r "$file" ]]; then
                              . "$file"
                      fi
              done
      fi
    '';
  };

  programs.fzf = {
    enable = true;
    enableBashIntegration = true;
  };

  programs.lesspipe.enable = true;

  programs.dircolors = {
    enable = true;
    enableBashIntegration = true;
  };

  programs.bash-git-prompt = {
    enable = true;
    customThemeFile = ./git-prompt-colors.sh;
  };
}
