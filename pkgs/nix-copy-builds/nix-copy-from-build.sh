#!@BASH@
set -euo pipefail

# Expanding a glob that doesn't match should result in zero entries, so the
# glob list can be checked more easily.
shopt -s nullglob

# Don't care about ordering of globs.
GLOBSORT=nosort

export PATH=@PATH@

targets=()
nix_copy_args=()
while (( $# > 0 )); do
    case "$1" in
        --substitute-on-destination|-s)
            nix_copy_args+=(--substitute-on-destination)
            shift
            ;;
        --)
            shift
            targets+=("$@")
            break
            ;;
        *)
            targets+=("$1")
            shift
            ;;
    esac
done

if (( ${#targets[*]} == 0 )); then
    exit 64
fi

did_something=
while :; do
    paths=(/tmp/nix-copy-post-build-hook/*)

    if (( ${#paths[*]} == 0 )); then
        if [[ "$did_something" ]]; then
            echo 'finished' >&2
	    exit 0
        else
            echo 'nothing to copy' >&2
	    exit 64
        fi
    fi

    # Avoid "argument list too long" errors.  Could be smarter here, but just
    # keeping the argument list to a reasonable length should be good enough.
    # Large numbers seem to slow things down due to the need to compute the
    # closures and query what already exists on the remote.  1000 seemed
    # definitely too long; 64 seems to work reasonably well.
    paths=("${paths[@]::64}")

    for target in "${targets[@]}"; do
        nix copy "${nix_copy_args[@]}" --to "$target" "${paths[@]}"
    done

    rm -- "${paths[@]}"

    did_something=Yes
done

# vim: et ts=4
