{
  writeCheckedShellApplication,
  coreutils,
  pv,
}:
writeCheckedShellApplication {
  name = "sleep_until";
  runtimeInputs = [
    coreutils
    pv
  ];
  text = ''
    declare -ir EX_USAGE=64

    # Make sure we don't accidentally inherit an environment variable
    unset target
    quiet=

    set_target () {
        if [[ -v target ]]; then
            printf 'unexpected argument %q\n' "$1" >&2
            exit "$EX_USAGE"
        fi
        target="$1"
    }

    while (( $# > 0 )); do
        case "$1" in
            -q|--quiet)
                quiet=Yes
                shift
                ;;
            --)
                set_target "$2"
                shift 2
                ;;
            *)
                set_target "$1"
                shift
                ;;
        esac
    done

    target_epoch="$(date -d "$target" +%s)"
    sleep_time="$((target_epoch - EPOCHSECONDS))"

    report_sleep () {
        if (( $1 == 1 )); then
            printf 'sleeping for one second\n' >&2
        elif (( $1 < 60 )); then
            printf 'sleeping for %d seconds\n' "$1" >&2
        else
            # Integer division rounds down, but we want to round up.  Handle
            # that by subtracting one pre-division, and adding one
            # post-divison.
            local val unit
            if (( $1 < (60*60) )); then
                unit='minute'
                val="$(( ($1-1)/60 + 1))"
            elif (( $1 < (60*60*24) )); then
                unit='hour'
                val="$(( ($1-1)/60/60 + 1 ))"
            elif (( $1 < (60*60*24*7) )); then
                unit='day'
                val="$(( ($1-1)/60/60/24 + 1 ))"
            elif (( $1 < (60*60*24*30) )); then
                unit='week'
                val="$(( ($1-1)/60/60/24/7 + 1 ))"
            elif (( $1 < (60*60*24*365) )); then
                unit='month'
                val="$(( ($1-1)/60/60/24/30 + 1))"
            else
                unit='year'
                val="$(( ($1-1)/60/60/24/365 + 1 ))"
            fi

            if (( val != 1 )); then
                unit="''${unit}s"
            fi

            printf "sleeping for %'d seconds (~%'d %s)\n" "$1" "$val" "$unit" >&2
        fi
    }

    do_sleep () {
        if [[ "$quiet" ]]; then
            sleep "$@"
        else
            report_sleep "$@"
            sleep "$@" | pv -t
        fi
    }

    if (( sleep_time <= 0 )); then
        printf 'time %s (@%d / %(%c)T) has already passed\n' "$target" "$target_epoch" "$target_epoch" >&2
        exit "$EX_USAGE"
    fi

    do_sleep "$sleep_time"
  '';
}
