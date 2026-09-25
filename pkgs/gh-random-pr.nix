{
  writeCheckedShellApplication,
  jq,
  gh,
  coreutils,
  file-age,
}:
writeCheckedShellApplication {
  name = "gh-random-pr";
  runtimeInputs = [
    jq
    gh
    coreutils
    file-age
  ];
  text = ''
    declare -ir EX_USAGE=64

    declare force="" open=""
    declare -i max_age=$((60 * 60))
    declare -i limit=10000
    while getopts fa:l:w opt; do
        case "$opt" in
            f)  force=YesPlease;;
            a)  max_age="$OPTARG";;
            l)  limit="$OPTARG";;
            w)  open=YesPlease;;
            *)  echo "gh-random-pr: unexpected argument -$opt" >&2
                exit "$EX_USAGE"
                ;;
        esac
    done

    if [[ -v GH_RANDOM_PR_CACHE ]]; then
        cache_file="$GH_RANDOM_PR_CACHE"
    elif [[ -v XDG_CACHE_HOME ]]; then
        cache_file="$XDG_CACHE_HOME/gh-random-pr-cache"
    else
        cache_file="$HOME"/.cache/gh-random-pr-cache
    fi

    if [[ -z "$force" ]]; then
        age="$(file-age -f "$cache_file")"
    fi

    if [[ "$force" ]] || (( age > max_age )); then
        echo "Updating PR cache"
        gh pr list \
            -R NixOS/nixpkgs \
            --json title,url,isDraft,labels,createdAt,updatedAt \
            --jq '
                def fmtutcdate:
                  strptime("%Y-%m-%dT%H:%M:%SZ")
                  | mktime
                  | strftime("%a %e %b %Y %H:%M UTC")
                  ;
                map(
                  select(.isDraft | not)
                  | del(.isDraft)
                  | .createdAt |= fmtutcdate
                  | .updatedAt |= fmtutcdate
                  | .labels |= map(.name)
                )
            ' \
            -L "$limit" \
            > "$cache_file.tmp"
        mv "$cache_file".tmp "$cache_file"
    fi

    # shellcheck disable=SC2312 # Get return code with `wait`.
    while read -r line; do
        printf '%s\n' "$line"
        if [[ "$line" = https://* ]]; then
            url="$line"
        fi
    done < <(
        jq \
            --raw-output \
            --argjson srandom "$SRANDOM" \
            '.[$srandom % length]
             | (
                 .title,
                 "Created: \(.createdAt)",
                 "Last update: \(.updatedAt)",
                 if .labels != []
                 then "Labels: \(.labels | join(", "))"
                 else empty
                 end,
                 .url
               )' \
            "$cache_file"
    )
    wait "$!"

    if [[ "$open" && "$url" ]]; then
        xdg-open "$url"
    fi
  '';
}
