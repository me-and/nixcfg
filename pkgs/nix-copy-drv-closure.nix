{
  writeCheckedShellApplication,
  coreutils,
  findutils,
  moreutils,
  pv,
  nix-add-drv-root,
}:
writeCheckedShellApplication {
  name = "nix-copy-drv-closure";
  runtimeInputs = [
    coreutils
    findutils
    moreutils
    pv
    nix-add-drv-root
  ];
  text = ''
    once_only=
    max_sleep=$((60*5))
    while (( $# > 0 )); do
        case "$1" in
            -o|--once)
                once_only=Yes
                shift
                ;;
            -t|--max-sleep)
                max_sleep="$2"
                shift 2
                ;;
            -t*)
                set -- "''${1: 0:2}" "''${1: 2}" "''${@: 2}"
                ;;
            --max-sleep=*)
                set -- "''${1%%=*}" "''${1#*=}" "''${@: 2}"
                ;;
            --)
                shift
                positional_args+=("$@")
                break
                ;;
            *)
                positional_args+=("$1")
                shift
                ;;
        esac
    done

    if (( ''${#positional_args[*]} == 0 )); then
        exit 64 # EX_USAGE
    elif (( ''${#positional_args[*]} == 1 )); then
        echo 'nothing to copy' >&2
        exit 0
    fi

    process_positional_args () {
        destination="$1"
        shift
        derivations=("$@")
    }

    process_positional_args "''${positional_args[@]}"

    if [[ -v RUNTIME_DIRECTORY ]]; then
        workdir="$RUNTIME_DIRECTORY"
    else
        workdir="$(mktemp -d --tmpdir nix-copy-drv-closure.$$.XXXXX)"
        trap 'rm -rf -- "$workdir"' EXIT
    fi

    # Add derivation roots to make sure the things we're copying don't get lost
    # thanks to a mistimed garbage collection.  Depending on what's being built
    # and copied, that might be impossible anyway, but this costs essentially
    # nothing and will be useful in at least some circumstances.
    #
    # TODO Handle the case where `keep-derivations` and/or `keep-outputs` isn't
    # true, as this code won't provide much protection in that circumstance.
    nix-add-drv-root --root "$workdir"/result "''${derivations[@]}"

    # shellcheck disable=SC2312 # exit code handled with `wait "$!"`
    mapfile -t output_paths < <(nix-store --query --outputs "''${derivations[@]}")
    wait "$!"

    if [[ "$once_only" ]]; then
        nix-store --query --requisites --include-outputs "''${derivations[@]}" |
            xargs -r nix copy --to "$destination"
    else
        t=1
        final_loop=
        touch "$workdir"/xfered
        while :; do
            nix-store --query --requisites --include-outputs "''${derivations[@]}" |
                combine - not "$workdir"/xfered |
                tee "$workdir"/current-xfer |
                xargs -r nix copy --to "$destination"

            if [[ "$final_loop" ]]; then
                # We just did the final copy after spotting all outputs were
                # available, so there's no chance there's anything left to copy.
                exit 0
            fi

            if [[ -s "$workdir"/current-xfer ]]; then
                t=1
                cat "$workdir"/current-xfer >>"$workdir"/xfered

                missing_output=
                for output in "''${output_paths[@]}"; do
                    if [[ ! -e "$output" ]]; then
                        missing_output=Yes
                        break
                    fi
                done

                if [[ -z "$missing_output" ]]; then
                    # We can see all the output paths.  Don't exit just yet, on the
                    # off-chance there was a timing window between the last copy
                    # finishing and the output paths being available.  Quite
                    # plausible, given the copy might have taken a while, but will
                    # be using a list of paths from when it started, not when it
                    # ended.
                    final_loop=Yes
                fi
            else
                t="$((t*2))"
                if (( t > max_sleep )); then
                    t="$max_sleep"
                fi
                if [[ -t 0 ]]; then
                    sleep "$t" | pv -t
                else
                    sleep "$t"
                fi
            fi
        done
    fi
  '';
}
