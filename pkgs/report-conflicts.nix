# Look for files with names that indicate they're some sort of sync conflict.
{
  writeCheckedShellApplication,
  findutils,
}:
writeCheckedShellApplication {
  name = "report-conflicts";
  runtimeInputs = [ findutils ];
  text = ''
    paths=()
    action_args=(-print)

    while (( $# > 0 )); do
        case "$1" in
        -0) action_args=(-print0)
            shift
            ;;
        --) shift
            paths+=("$@")
            break
            ;;
        -*) printf 'unexpected argument %s\n' "$1" >&2
            exit 64 # EX_USAGE
            ;;
        *)  paths+=("$1")
            shift
            ;;
        esac
    done

    if (( ''${#paths[*]} == 0 )); then
        echo 'no paths specified' >&2
        exit 64 # EX_USAGE
    fi

    # shellcheck disable=SC2185 # passing paths using -files0-from
    printf '%s\0' "''${paths[@]}" | find -files0-from - -regextype egrep \( -type d \( -name .stversions -o -name .stfolder \) -prune \) -o \( \( -name '*.sync-conflict-*' -o -iregex '.*\.conflict[0-9]+' -o -iregex '.*-(multivac|hex|kryten|a-4d6hh84|(win|desktop|pc)-[a-z0-9]{7,14})(\.[^\./]*)?' \) "''${action_args[@]}" \)
  '';
}
