#!@BASH@
set -euo pipefail
export PATH=@PATH@

workdir=/tmp/nix-copy-post-build-hook
mkdir -p -- "$workdir"

drv_name="${DRV_PATH##*/}"
# shellcheck disable=SC2153 # This is the correct spelling
read -r -a out_paths <<<"$OUT_PATHS"

# Use the first out path as a temporary target to create a root for the
# derivation.
# shellcheck disable=SC2128 # Only want first array element
nix-store --realise --add-root "$workdir"/"$drv_name" "$out_paths"
ln -s --force --no-dereference -- "$DRV_PATH" "$workdir"/"$drv_name"

real_target="$(realpath "$workdir"/"$drv_name")"

if [[ "$DRV_PATH" != "$real_target" ]]; then
    echo 'target unexpectedly mismatched' >&2
    echo "expected $DRV_PATH" >&2
    echo "found $real_target" >&2
    exit 74 # EX_IOERR
elif [[ ! -e "$DRV_PATH" ]]; then
    echo 'failed to find derivation path after root creation' >&2
    echo 'maybe a badly timed garbage collection?' >&2
    exit 75 # EX_TEMPFAIL
fi

# Create temporary roots for the actual targets.
nix-store --realise --add-root "$workdir"/"$drv_name"-result "${out_paths[@]}"
