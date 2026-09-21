{
  writeCheckedShellApplication,
  coreutils,
  findutils,
}:
writeCheckedShellApplication {
  name = "nix-add-drv-root";
  runtimeInputs = [
    coreutils
    findutils
  ];
  text = ''
    # Set up a garbage collection root for our target derivation by first
    # creating one normally (so there's a registered root) then update the
    # symlink to our target (so the registered root is the one we need it to
    # be).

    target="$1"
    root="''${2:-result}"

    if [[ "$target" != /nix/store/*.drv || "$target" = /nix/store/*/* ]]; then
        echo "not a derivation: $target" >&2
        exit 64 # EX_USAGE
    fi

    # Temporary target just has to be a real non-derivation store path.  We're
    # not at all fussed about which one.
    temp_target="$(
        find /nix/store \
        -mindepth 1 -maxdepth 1 \
        \! -name '*.drv' \
        \! -name '.*' \
        \! -name '*.chroot' \
        \! -name '*.lock' \
        -print -quit
    )"
    nix-store --realise --add-root "$root" "$temp_target"
    rm -f -- "$root"
    ln -s --force -- "$target" "$root"

    real_target_path="$(realpath "$target")"
    real_root_path="$(realpath "$root")"

    if [[ "$real_target_path" != "$real_root_path" ]]; then
        echo 'root target unexpectedly mismatched' >&2
        echo "expected $real_target_path" >&2
        echo "found $real_root_path" >&2
        exit 74 # EX_IOERR
    elif [[ ! -e "$real_target_path" || -h "$real_target_path" ]]; then
        echo 'failed to resolve target after root creation' >&2
        echo 'maybe a badly timed garbage collection?' >&2
        exit 75 # EX_TEMPFAIL
    fi
  '';
}
