{ writeCheckedShellApplication, jq }:
writeCheckedShellApplication {
  name = "taskwarrior-ghmeta-web";
  runtimeInputs = [ jq ];
  text = ''
    declare -ir EX_USAGE=64
    declare -ir EX_DATAERR=65
    declare -ir EX_SOFTWARE=70

    action=open
    filter=()

    while (( $# > 0 )); do
        case "$1" in
            -p|--print)
                action=print
                shift
                ;;
            --)
                shift
                filter+=("$@")
                break
                ;;
            *)
                filter+=("$1")
                shift
                ;;
        esac
    done

    # The jq command here is a bit of a mess because Taskwarrior is (at least
    # for now) mangling escapes in ghmeta attributes across taskserver syncs,
    # which means we can't reliably parse the JSON.  Thankfully the format of
    # the part we care about is pretty straightforward, so we can just process
    # the text instead.
    #
    # shellcheck disable=SC2312 # Get return code with `wait`.
    mapfile -t -n 6 urls < <(task "''${filter[@]}" export | jq --raw-output '.[].ghmeta | values | capture("\"url\":\"(?<url>.*?)\"").url')
    if wait "$!"; then
        wait_rc=0
    else
        wait_rc="$?"
    fi

    if (( "''${#urls[*]}" > 5 )); then
        echo 'Too many urls found' >&2
        echo 'Maybe you used too wide a filter?' >&2
        exit "$EX_USAGE"
    elif (( wait_rc != 0 )); then
        echo 'Unexpected return code from task/jq pipeline' >&2
        echo "rc: $wait_rc" >&2
        exit "$EX_SOFTWARE"
    fi

    case "$action" in
        print)
            printf '%s\n' "''${urls[@]}"
            ;;
        open)
            for url in "''${urls[@]}"; do
                if [[ "$url" = https://github.com/* ]]; then
                    xdg-open "$url"
                else
                    echo 'Unexpected url!' >&2
                    printf 'Received: %s\n' "$url" >&2
                    exit "$EX_DATAERR"
                fi
            done
            ;;
        *)
            echo "Unexpected action: $action" >&2
            exit "$EX_SOFTWARE"
            ;;
    esac
  '';
}
