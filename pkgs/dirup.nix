# b/c -> c, safely and even if b and c have the same name
{ writeCheckedShellApplication }:
writeCheckedShellApplication {
  name = "dirup";
  text = ''
    shopt -s dotglob nullglob

    declare -ir EX_USAGE=64

    non_option_args=()
    verbosity=0
    while (( $# > 0 )); do
        case "$1" in
            -h|--help)
                echo 'dirup [-h] [-v]* [--] <dir>'
                echo
                echo 'Flatten a directory containing a single entry by one level'
                echo
                echo 'Given a directory structure a/b/c/d, running `dirup a` will'
                echo 'rename things to a/c/d.'
                echo
                echo '  -h|--help:'
                echo '    Print this help message.'
                echo '  -v|--verbose:'
                echo "    Provide more detail about what's happening.  Can be"
                echo '    specified multiple times.'
                exit 0
                ;;
            -v|--verbose)
                (( ++verbosity ))
                shift
                ;;
            -h*|-v*)
                set -- "-''${1: 1:1}" "-''${1: 2}" "''${@: 2}"
                ;;
            --)
                shift
                non_option_args+=("$@")
                break
                ;;
            -*)
                echo "unexpected argument ''${1@Q}" >&2
                exit "$EX_USAGE"
                ;;
            *)
                non_option_args+=("$1")
                shift
                ;;
        esac
    done

    if (( ''${#non_option_args[*]} == 0 )); then
        echo 'no target specified' >&2
        exit "$EX_USAGE"
    elif (( ''${#non_option_args[*]} > 1 )); then
        echo "unexpected argument ''${non_option_args[1]@Q}" >&2
        exit "$EX_USAGE"
    fi

    target="''${non_option_args[0]}"

    if [[ ! -d "$target" ]]; then
        echo "not a directory: $target" >&2
        exit "$EX_USAGE"
    fi

    contents=("$target"/*)
    if (( ''${#contents[*]} == 0 )); then
        echo "empty directory: $target" >&2
        exit "$EX_USAGE"
    elif (( ''${#contents[*]} > 1 )); then
        echo "multiple items in directory: $target" >&2
        exit "$EX_USAGE"
    fi

    content="''${contents[0]}"

    if [[ "$target" = */* ]]; then
        mktemp_args=(-p "''${target%/*}")
    else
        mktemp_args=()
    fi

    if [[ ! -d "$content" ]]; then
        echo "not a directory: $content" >&2
        if [[ "$target" = */* ]]; then
            echo "you gave ''${target@Q} as the target" >&2
            parent_target="''${target%/*}"
            echo "did you mean ''${parent_target@Q}?" >&2
        fi
        exit "$EX_USAGE"
    fi

    # Fine to use `mktemp -u`, as we're using it with `mv -n` to avoid race
    # conditions.
    tmp_name="$(mktemp -u "''${mktemp_args[@]}" dirup.XXXXX)"

    if (( verbosity > 0 )); then
        echo 'plan:'
        echo "1. move ''${content@Q} to ''${tmp_name@Q}"
        echo "2. delete the now-empty ''${target@Q}"
        echo "3. move ''${tmp_name@Q} to ''${target@Q}"
    fi >&2

    if (( verbosity > 1 )); then
        verbosity_args=(-v)
    else
        verbosity_args=()
    fi

    mv -n "''${verbosity_args[@]}" -- "$content" "$tmp_name"
    rm -d "''${verbosity_args[@]}" -- "$target"
    mv -n "''${verbosity_args[@]}" -- "$tmp_name" "$target"
  '';
}
