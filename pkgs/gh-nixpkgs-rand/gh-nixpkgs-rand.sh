#!/usr/bin/env bash
set -euo pipefail
shopt -s extglob

declare -ir EX_USAGE=64
declare -ir EX_UNAVAILABLE=69
declare -ir EX_SOFTWARE=70
declare -ir EX_CONFIG=78

open=
max_age=$(( 60 * 60 ))
force=0
count=1
mode='all'
while (( $# > 0 )); do
    case "$1" in
        # Mode
        --all|-a)
            mode='all'
            shift
            ;;
        --issue|-i)
            mode='issue'
            shift
            ;;
        --pr|-p)
            mode='pr'
            shift
            ;;

        # Other options
        --count|-n)
            count="$2"
            shift 2
            ;;
        --force|-f)
            force=$((force + 1))
            shift
            ;;
        --web|-w)
            open=YesPlease
            shift
            ;;

        # Expand short options that don't take parameters.
        -[aipfw]*)
            set -- "${1:0:2}" "-${1:2}" "${@:2}"
            ;;

        # Expand short options that do take parameters.
        -n*)
            set -- "${1:0:2}" "${1:2}" "${@:2}"
            ;;

        # Expand long arguments that take parameters.
        --count=*)
            set -- "${1%%=*}" "${1#*=}" "${@:2}"
            ;;

        *)
            printf 'gh-nixpkgs-rand: unexpected argument %q\n' "$1" >&2
            exit "$EX_USAGE"
            ;;
    esac
done

if [[ -v GH_NIXPKGS_RAND_CACHE ]]; then
    cache_dir="$GH_NIXPKGS_RAND_CACHE"
elif [[ -v XDG_CACHE_HOME ]]; then
    cache_dir="$XDG_CACHE_HOME"/gh-nixpkgs-rand
elif [[ -v HOME ]]; then
    cache_dir="$HOME"/.cache/gh-nixpkgs-rand
else
    printf 'gh-nixpkgs-rand: no HOME in environment\n' >&2
    exit "$EX_CONFIG"
fi

if [[ "$open" && ! -v BROWSER ]]; then
    if BROWSER="$(command -v xdg-open)"; then
        :
    else
        printf 'gh-nixpkgs-rand: no BROWSER in environment\n' >&2
        exit "$EX_CONFIG"
    fi
fi

for prog in mkdir flock rm gh touch date jq shuf; do
    if ! command -v "$prog" >/dev/null; then
        printf 'gh-nixpkgs-rand: %s not found in PATH\n' "$prog" >&2
        exit "$EX_UNAVAILABLE"
    fi
done

mkdir -p -- "$cache_dir"
lockfile="$cache_dir/lockfile"
cache_file="$cache_dir/cache.jsonl"
new_cache_file="$cache_dir/new_cache.jsonl"
update_file="$cache_dir/updates.jsonl"
prev_update_ts="$cache_dir/stamp-updated"
current_update_ts="$cache_dir/stamp-update-in-progress"

exec {lock_fd}>"$lockfile"

if (( force >= 2 )); then
    rm -f -- "$prev_update_ts"
fi

if [[ ! -e "$cache_file" || ! -e "$prev_update_ts" ]]; then
    if flock -xn "$lock_fd"; then
        :
    else
        printf 'gh-nixpkgs-rand: waiting for cache write lock\n' >&2
        flock -x "$lock_fd"
    fi

    touch -- "$current_update_ts"

    gh api repos/NixOS/nixpkgs/issues \
        --method GET \
        --paginate \
        -f per_page=100 \
        -f state=open \
        --jq '.[] | {number, title, state, created_at, updated_at, labels, draft, pull_request, html_url} | .labels |= map(.name) | .pull_request |= . != null' \
        >"$new_cache_file"

    mv -- "$new_cache_file" "$cache_file"
    mv -- "$current_update_ts" "$prev_update_ts"
else
    prev_update_epoch="$(date -r "$prev_update_ts" +%s)"

    if (( force >= 1 )) || (( (EPOCHSECONDS - prev_update_epoch) > max_age )); then
        if flock -xn "$lock_fd"; then
            :
        else
            printf 'gh-nixpkgs-rand: waiting for cache write lock\n' >&2
            flock -x "$lock_fd"
        fi

        touch -- "$current_update_ts"

        # Work out the time one second earlier than the previous update, to
        # avoid off-by-one errors meaning we miss updates.
        since_epoch=$(( prev_update_epoch - 1))
        TZ=UTC printf -v since '%(%Y-%m-%dT%H:%M:%S)TZ' "$since_epoch"

        gh api repos/NixOS/nixpkgs/issues \
            --method GET \
            --paginate \
            -f per_page=100 \
            -f state=all \
            -f since="$since" \
            --jq '.[] | {number, title, state, created_at, updated_at, labels, draft, pull_request, html_url} | .labels |= map(.name) | .pull_request |= . != null' \
            >"$update_file"

        jq \
            --compact-output \
            --slurpfile updates "$update_file" \
            --slurp \
            --from-file ./updates.jq \
            -- "$cache_file" \
            >"$new_cache_file"

        mv -- "$new_cache_file" "$cache_file"
        mv -- "$current_update_ts" "$prev_update_ts"
        rm -- "$update_file"
    fi
fi

if flock -sn "$lock_fd"; then
    :
else
    printf 'gh-nixpkgs-rand: waiting for cache read lock\n' >&2
    flock -s "$lock_fd"
fi

first=Yes
case "$mode" in
    all)
        shuf -n "$count" -- "$cache_file"
        ;;
    issue)
        jq -c 'select(.pull_request | not)' -- "$cache_file" | shuf -n "$count"
        ;;
    pr)
        jq -c 'select(.pull_request)' -- "$cache_file" | shuf -n "$count"
        ;;
    *)
        exit "$EX_SOFTWARE"
        ;;
esac |
    while read -r line; do
        if [[ "$first" ]]; then
            first=
        else
            echo
        fi

        jq \
            --from-file ./display.jq \
            --raw-output \
            <<<"$line"
        if [[ "$open" ]]; then
            url="$(jq --raw-output '.html_url' <<<"$line")"
            "$BROWSER" "$url"
        fi
    done

# vim: et ts=4
