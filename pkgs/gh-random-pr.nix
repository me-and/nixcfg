{
  writeCheckedShellApplication,
  jq,
  gh,
  coreutils,
  file-age,
}:
writeCheckedShellApplication {
  name = "gh-random-pr";
  purePath = true;
  runtimeInputs = [
    jq
    gh
    coreutils
    file-age
  ];
  text = ''
    declare -ir EX_USAGE=64

    declare force=
    declare -i max_age=$((60 * 60))
    declare -i limit=10000
    while getopts fa:l: opt; do
        case "$opt" in
            f)  force=YesPlease;;
            a)  max_age="$OPTARG";;
            l)  limit="$OPTARG";;
            *)  echo "gh-random-pr: unexpected argument -$opt" >&2
                exit "$EX_USAGE"
                ;;
        esac
    done

    if [[ -v GH_RANDOM_PR_CACHE ]]; then
        cache_file="$GH_RANDOM_PR_CACHE"
    elif [[ -v XDG_CACHE_DIR ]]; then
        cache_file="$XDG_CACHE_DIR/gh-random-pr-cache"
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
  '';
}
