# b/c -> c, safely and even if b and c have the same name
{ writeCheckedShellApplication }:
writeCheckedShellApplication {
  name = "dirup";
  text = ''
    shopt -s dotglob nullglob

    if [[ "$1" = -- ]]; then
        shift
    elif [[ "$1" = -* ]]; then
        echo 'dirup accepts no options' >&2
        exit 64
    fi

    target="$1"

    if [[ ! -d "$target" ]]; then
        echo "not a directory: $target" >&2
        exit 64
    fi

    contents=("$target"/*)
    if (( ''${#contents[*]} == 0 )); then
        echo "empty directory: $target" >&2
        exit 64
    elif (( ''${#contents[*]} > 1 )); then
        echo "multiple items in directory: $target" >&2
        exit 64
    fi

    content="''${contents[0]}"
    parent="$(dirname -- "$target")"

    tmp_name="$(mktemp -u -p "$parent" dirup.XXXXX)"

    mv -n -- "$content" "$tmp_name"
    rm -d -- "$target"
    mv -n -- "$tmp_name" "$target"
  '';
}
