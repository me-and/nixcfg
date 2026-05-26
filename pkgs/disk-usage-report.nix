{
  writeCheckedShellApplication,
  nix-dangling-roots,
}:
# TODO turn this horrible pipeline into something more useful.  Idea is to get
# a report of all the roots and how much each root contributes to the store
# size above the previous root.  Probably also wants to have some more useful
# sorting than 'sort -uV | tac`, too.
#
# prev_size=0 && targets=() && sudo nix-dangling-roots -at | sort -uV | tac | while read -r target; do targets+=("$target") && printf '%s\t' "$target" && sudo nix-store -q -R "${targets[@]}" | sort -u | tr '\n' '\0' | sudo du -cs --block-size=1 --files0-from=- | sed -n 's/\ttotal$//p'; done | { while IFS=$'\t' read -r target size; do printf '%d\t%s\n' "$((size - prev_size))" "$target" && prev_size="$size"; done; printf '\t%d\ttotal\n' "$prev_size"; } | python3 coloury.py | numfmt --suffix=B --delimiter=$'\t' --to=iec-i --field=2 | sed 's/\t//'
#
# where coloury.py is the following:
#
# #!/usr/bin/env python3
# import sys
# 
# RESET = "\x1b[0m"
# 
# def gradient_rgb(t):
#     """
#     Map t in [0.0, 1.0] to an RGB tuple along green → yellow → red.
#     Green = (0, 200, 0), Yellow = (255, 200, 0), Red = (220, 0, 0).
#     Using a muted green/red rather than pure to avoid harshness.
#     """
#     if t <= 0.5:
#         # Green to yellow: ramp red up from 0 to 255
#         s = t * 2
#         return (round(s * 255), 200, 0)
#     else:
#         # Yellow to red: ramp green down from 200 to 0
#         s = (t - 0.5) * 2
#         return (255, round((1 - s) * 200), 0)
# 
# def colour_for(value, lo, hi):
#     t = 0.0 if hi == lo else max(0.0, min(1.0, (value - lo) / (hi - lo)))
#     r, g, b = gradient_rgb(t)
#     return f"\x1b[38;2;{r};{g};{b}m"
# 
# lines = sys.stdin.read().splitlines()
# 
# parsed = []
# for line in lines:
#     parts = line.split("\t", 1)
#     if len(parts) == 2 and parts[0].strip().isdigit() and parts[1].strip() != "total":
#         parsed.append((int(parts[0]), parts[1]))
#     else:
#         parsed.append(None)
# 
# nums = [n for entry in parsed if entry for n, _ in [entry]]
# lo, hi = (min(nums), max(nums)) if nums else (0, 1)
# 
# for i, line in enumerate(lines):
#     entry = parsed[i]
#     if entry is None:
#         print(line)
#     else:
#         n, path = entry
#         print(f"{colour_for(n, lo, hi)}\t{n}\t{path}{RESET}")
writeCheckedShellApplication {
  name = "disk-usage-report";
  runtimeInputs = [ nix-dangling-roots ];
  text = ''
    tmpdir="$(mktemp -d --tmpdir disk-usage-report.XXXXX)"
    trap 'rm -rf "$tmpdir"' EXIT

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
