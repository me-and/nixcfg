# A useful Bash trick that I don't want to forget.
{ writeCheckedShellApplication }:
writeCheckedShellApplication {
  name = "proc-cmdline";
  text = ''
    pids=()
    sep=$'\n'

    declare -ir EX_USAGE=64
    declare -ir EX_NOINPUT=66

    while (( $# > 0 )); do
        case "$1" in
            -s)
                sep="$2"
                shift 2
                ;;
            -s*)
                sep="''${1#-s}"
                shift
                ;;
            --)
                shift
                pids+=("$@")
                break
                ;;
            -*)
                printf 'unexpected argument %q\n' "$1" >&2
                exit "$EX_USAGE"
                ;;
            *)
                pids+=("$1")
                shift
                ;;
        esac
    done

    report_pid () {
        if mapfile -d "" -t </proc/"$1"/cmdline; then
            printf '%q'"$sep" "''${MAPFILE[@]}"
        else
            rc="$?"
            if [[ ! -e /proc/"$1" ]]; then
                # No need to produce an error message: bash will have produced
                # one when it failed to open the file.
                rc="$EX_NOINPUT"
            else
                echo "Unexpected error rc $rc" >&2
            fi
        fi
    }

    rc=0

    if (( ''${#pids[*]} == 0 )); then
        printf 'no pid specified' >&2
        exit "$EX_USAGE"
    elif (( ''${#pids[*]} == 1 )); then
        report_pid "''${pids[0]}"
    else
        for pid in "''${pids[@]}"; do
            printf '%d%s' "$pid" "$sep"
            report_pid "$pid"
            printf '%s' "$sep"
        done
    fi

    exit "$rc"
  '';
}
