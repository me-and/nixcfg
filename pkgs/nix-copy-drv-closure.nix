{
  writeCheckedShellApplication,
  coreutils,
  findutils,
  moreutils,
  pv,
}:
writeCheckedShellApplication {
  name = "nix-copy-drv-closure";
  runtimeInputs = [
    coreutils
    findutils
    moreutils
    pv
  ];
  text = ''
    if (( $# != 2 )); then
        exit 64 # EX_USAGE
    fi

    derivation="$1"
    destination="$2"

    if [[ -v RUNTIME_DIRECTORY ]]; then
        workdir="$RUNTIME_DIRECTORY"
    else
        workdir="$(mktemp -d --tmpdir nix-copy-drv-closure.$$.XXXXX)"
        trap 'rm -rf -- "$workdir"' EXIT
    fi

    cd "$workdir"

    # Set up a garbage collection root for our target derivation by first
    # creating one normally (so there's a registered root) then update the
    # symlink to our target (so the registered root is the one we need it to
    # be).
    create_gc_root () {
        local target="$1"
        local temp_target

        # Temporary target just has to be a real non-derivation store path.
        # We're not at all fussed about which one.
        temp_target="$(
            find /nix/store \
            -mindepth 1 -maxdepth 1 \
            \! -name '*.drv' \
            \! -name '.*' \
            \! -name '*.chroot' \
            \! -name '*.lock' \
            -print -quit
        )"
        nix-store --realise --add-root result "$temp_target"
        ln -s --force "$target" result

        local real_target_path real_result_path
        real_target_path="$(realpath "$target")"
        real_result_path="$(realpath result)"
        if [[ "$real_target_path" != "$real_result_path" ]]; then
                printf 'root target unexpectedly mismatched\n' >&2
                printf 'expected %s\n' "$real_target_path" >&2
                printf 'found %s\n' "$real_result_path" >&2
                exit 74 # EX_IOERR
        elif [[ ! -e "$real_target_path" || -h "$real_target_path" ]]; then
                printf 'failed to resolve target after root creation\n' >&2
                printf 'maybe a badly timed garbage collection?\n' >&2
                exit 75 # EX_TEMPFAIL
        fi
    }

    # shellcheck disable=SC2312 # exit code handled with `wait "$!"`
    mapfile -t output_paths < <(nix-store --query --outputs "$derivation")
    wait "$!"

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
                cat current-xfer >>xfered
            fi
        else
            t="$((t*2))"
            if (( t > (60*5) )); then
                t="$((60*5))"
            fi
            sleep "$t" | pv -t
        fi
    done
  '';
}
