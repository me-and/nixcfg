{
  diffutils,
  ncurses,
  bashInteractive,
  writeCheckedShellApplication,
}:
writeCheckedShellApplication {
  name = "coldiff";
  purePath = true;
  #shell = "${bashInteractive}/bin/bash";
  text = ''
    width=""

    # The only argument that gets handled specially is a width specification,
    # which must be the first argument, although it can be in any format that
    # diff accepts.  Everything else gets passed through to diff.
    case "$1" in
    --width|-W)
        width="$2"
        shift 2
        ;;
    --width=*)
        width="''${1#--width=}"
        shift
        ;;
    -W*)
        width="''${1#-W}"
        shift
        ;;
    esac

    if [[ -z "$width" ]]; then
        width="$(${ncurses}/bin/tput cols)"
    fi

    exec ${diffutils}/bin/diff \
        --width="$width" \
        --side-by-side \
        "$@"
  '';
}
