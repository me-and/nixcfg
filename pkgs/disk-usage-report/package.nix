{
  writeCheckedShellApplication,
  nix-dangling-roots,
  flock,
  python3,
}:
writeCheckedShellApplication {
  name = "disk-usage-report";
  runtimeInputs = [
    nix-dangling-roots
    flock
    python3
  ];
  text = ''
    rc=0

    round_up_frac_as_percentage () {
        local numerator denominator
        local -n result
        numerator="$1"
        denominator="$2"
        result="$3"
        result=$(( numerator * 1000 / denominator ))
        if [[ "$result" = *0 ]]; then
            result=$(( result / 10 ))
        else
            result=$(( result / 10 + 1 ))
        fi
    }

    df -h -xtmpfs -xdevtmpfs -xfuse.portal |
        grep -Fv ' /snap/'

    if [[ "$EUID" = 0 ]]; then
        # If we're root, get the big garbage collector lock to avoid things
        # changing under our feet.
        exec {gc_lock_fd}>/nix/var/nix/gc.lock
        flock -s "$gc_lock_fd"
    fi

    if [[ -e /nix/store ]]; then
        echo

        nix_store_size="$(du --summarize --block-size=1 /nix/store | cut -f1)"
        nix_store_size_h="$(numfmt --suffix=B --to=iec-i <<<"$nix_store_size")"
        echo "Nix store size: $nix_store_size_h"

        accessible_roots=()
        inaccessible_roots=()
        accessible_root_pairs=()

        # shellcheck disable=SC2312 # Get return code with `wait`.
        while IFS=$'\t' read -r target path; do
            if [[ -r "$target" ]]; then
                accessible_roots+=("$target")
                accessible_root_pairs+=("$target" "$path")
            else
                inaccessible_roots+=("$target")
            fi

        done < <(nix-dangling-roots -ap'%l\t%p\n')
        wait "$!" # Get return code from nix-dangling-roots

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
                du --total --summarize --block-size=1 --files0-from=- |
                sed -n 's/\ttotal$//p'
            )"
          nix_store_refd_size_h="$(numfmt --suffix=B --to=iec-i <<<"$nix_store_refd_size")"

        echo "Referenced store contents: $nix_store_refd_size_h"

        nix_store_disk_df="$(df --block-size=1 --output=size,avail /nix/store | tail -n1)"
        read -r nix_store_disk_size nix_store_disk_free <<<"$nix_store_disk_df"
        nix_store_disk_free_post_gc=$((nix_store_disk_free + nix_store_size - nix_store_refd_size))
        nix_store_disk_free_post_gc_h="$(numfmt --suffix=B --to=iec-i <<<"$nix_store_disk_free_post_gc")"

        round_up_frac_as_percentage \
            "$(( nix_store_disk_size - nix_store_disk_free_post_gc ))" \
            "$nix_store_disk_size" \
            nix_store_disk_size_used_pc

        echo "Store disk free after full GC: $nix_store_disk_free_post_gc_h (''${nix_store_disk_size_used_pc:?}% used)"

        echo

        echo 'Incremental usage by Nix roots:'
        prev_size=0
        roots=()
        printf '%s\t%s\n' "''${accessible_root_pairs[@]}" |
            sort -uVr |
            while IFS=$'\t' read -r target root; do
                if [[ -r "$target" ]]; then
                    roots+=("$root")
                    printf '%s\t' "$target"
                    nix-store -q -R "''${roots[@]}" |
                        tr '\n' '\0' |
                        du --total --summarize --block-size=1 --files0-from=- |
                        sed -n 's/\ttotal$//p'
                fi
            done |
            while IFS=$'\t' read -r target size; do
                printf '%d\t%s\n' "$((size - prev_size))" "$target"
                prev_size="$size"
            done |
            python3 ${./coloury.py} |
            numfmt --field=2 --suffix=B --delimiter=$'\t' --to=iec-i |
            sed 's/\t//'
    fi

    exit "$rc"
  '';
}
