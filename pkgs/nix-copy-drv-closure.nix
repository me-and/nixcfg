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
    positional_args=()
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

    if (( ''${#positional_args[*]} != 2 )); then
        exit 64 # EX_USAGE
    fi

    derivation="''${positional_args[0]}"
    destination="''${positional_args[1]}"

    if [[ -v RUNTIME_DIRECTORY ]]; then
        workdir="$RUNTIME_DIRECTORY"
    else
        workdir="$(mktemp -d --tmpdir nix-copy-drv-closure.$$.XXXXX)"
        trap 'rm -rf -- "$workdir"' EXIT
    fi

    cd "$workdir"

    # Add a derivation root to make sure the things we're copying don't get
    # lost thanks to a mistimed garbage collection.  Depending on what's being
    # built and copied, that might be impossible anyway, but this costs
    # essentially nothing and will be useful in at least some circumstances.
    nix-add-drv-root "$derivation"

    # shellcheck disable=SC2312 # exit code handled with `wait "$!"`
    mapfile -t output_paths < <(nix-store --query --outputs "$derivation")
    wait "$!"

    if [[ "$once_only" ]]; then
        nix-store --query --requisites --include-outputs "$derivation" |
            xargs -r nix copy --to "$destination"
    else
        t=1
        final_loop=
        touch xfered
        while :; do
            nix-store --query --requisites --include-outputs "$derivation" |
                combine - not xfered |
                tee current-xfer |
                xargs -r nix copy --to "$destination"

            if [[ "$final_loop" ]]; then
                # We just did the final copy after spotting all outputs were
                # available, so there's no chance there's anything left to copy.
                exit 0
            fi

            if [[ -s current-xfer ]]; then
                t=1
                cat current-xfer >>xfered

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
