# A useful Bash trick that I don't want to forget.
{ writeCheckedShellApplication }:
writeCheckedShellApplication {
  name = "proc-cmdline";
  text = ''
    pids=()
    sep='\n'

    declare -ir EX_USAGE=64

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
        mapfile -d "" -t </proc/"$1"/cmdline
        printf '%q'"$sep" "''${MAPFILE[@]}"
    }

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
  '';
}
