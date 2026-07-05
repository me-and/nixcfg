{ writeCheckedShellApplication }:
writeCheckedShellApplication {
  name = "cmdline";
  text = ''
    pid="$1"
    mapfile -d "" -t </proc/"$pid"/cmdline
    printf '%q\n' "''${MAPFILE[@]}"
  '';
}
