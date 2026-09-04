{
  writeCheckedShellApplication,
  nix-dangling-roots,
  flock,
  python3,
  bash,
}:
writeCheckedShellApplication {
  name = "disk-usage-report";
  runtimeInputs = [
    nix-dangling-roots
    flock
    python3
    bash
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


    if [[ -e /nix/store ]]; then
        keep_outputs="$(nix config show keep-outputs)"
        keep_derivations="$(nix config show keep-derivations)"

        if [[ "$keep_outputs" = 'false' ]]; then
            keep_outputs=
        fi
        if [[ "$keep_derivations" = 'false' ]]; then
            keep_derivations=
        fi

        nix_closure () {
            if [[ "$keep_outputs" ]]; then
                nix-store --query --requisites --include-outputs "$@"
            else
                nix-store --query --requisites "$@"
            fi
            if [[ "$keep_derivations" ]]; then
                nix-store --query --valid-derivers "$@" |
                    xargs -r nix-store --query --requisites
            fi
        }

        if [[ "$EUID" = 0 ]]; then
            # If we're root, get the big garbage collector lock to avoid things
            # changing under our feet.
            exec {gc_lock_fd}>/nix/var/nix/gc.lock
            flock -s "$gc_lock_fd"
        fi

        echo

        # Holding the GC lock stops real store paths vanishing under us, but
        # Nix creates and deletes lock files and chroot directories without
        # it, so an entry can disappear between find reading the directory
        # and find inspecting it.  Every exclusion below is a negated test,
        # and a test that can't stat() its target is false, so a vanished
        # entry escapes its exclusion and gets handed to du, which then fails
        # on the dead path.  `-links +0` guards against that: it needs a
        # successful stat(), it's true for anything that really exists, and
        # being a plain conjunct it makes the whole expression false when the
        # stat() fails.  Don't be tempted to use a `-type` test for this --
        # find can answer those from readdir's d_type without stat()ing at
        # all, and whether it does depends on the filesystem.  find still
        # warns and exits 1 for a vanished entry, which isn't fatal here.
        #
        # Suffixes alone can't identify Nix's temporary files, because the
        # store legitimately holds paths whose names end the same way, so
        # both exclusions below also check a property Nix gives its own
        # temporary files:
        #
        #   - a chroot directory is a derivation path plus `.chroot`, so
        #     stripping the suffix names an existing derivation, which isn't
        #     true of, say, a `test.drv.chroot` built by runCommand;
        #   - a lock file is mode 0600, whereas store paths are canonicalised
        #     to 0444 or 0555, which distinguishes one from a stored
        #     `Cargo.lock` or `Gemfile.lock`.
        nix_store_size="$({
            find /nix/store -maxdepth 1 -mindepth 1 -links +0 \
                \! \( -name .links -type d \) \
                \! \( -name '*.lock' -type f -empty -perm -u+w \) \
                \! \( -name '*.drv.chroot' -type d \
                      -exec bash -c '[[ -e "''${1%.chroot}" ]]' _ {} \; \) \
                -print0 || :
            } | du --total --summarize --block-size=1 --files0-from=- | sed -n 's/\ttotal$//p')"
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
            nix_closure "''${accessible_roots[@]}" |
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
                    nix_closure "''${roots[@]}" |
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
