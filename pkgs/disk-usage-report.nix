{
  writeCheckedShellApplication,
  nix-dangling-roots,
}:
writeCheckedShellApplication {
  name = "disk-usage-report";
  runtimeInputs = [ nix-dangling-roots ];
  text = ''
    tmpdir="$(mktemp -d --tmpdir disk-usage-report.XXXXX)"
    trap 'rm -rf "$tmpdir"' EXIT

    # exec >"$tmpdir"/output

    rc=0

    df -h -xtmpfs -xdevtmpfs -xfuse.portal |
        grep -Fv ' /snap/'

    if [[ -e /nix/store ]]; then
        echo

        nix_store_size="$(du -hs /nix/store | cut -f1)"
        echo "Nix store size: $nix_store_size"

        nix-dangling-roots -aT >"$tmpdir"/dangling-roots || rc="$?"
        mapfile -d "" -t roots <"$tmpdir"/dangling-roots
        accessible_roots=()
        inaccessible_roots=()
        for root in "''${roots[@]}"; do
            if [[ -r "$root" ]]; then
                accessible_roots+=("$root")
            else
                inaccessible_roots+=("$root")
            fi
        done

        if (( ''${#accessible_roots[*]} == 0 )); then
            echo 'no Nix store roots found' >&2
            rc=1
        elif (( ''${#inaccessible_roots[*]} > 0 )); then
            echo 'unable to check some Nix store roots' >&2
            echo 'try running the command as the root user' >&2
            rc=1
        fi

        nix_store_refd_size="$(
            nix-store -q -R "''${accessible_roots[@]}" |
                tr '\n' '\0' |
                sort -zu |
                du -hcs --files0-from=- |
                sed -n 's/\ttotal$//p'
            )"

        echo "Referenced store contents: $nix_store_refd_size"
    fi

    exit "$rc"
  '';
}
