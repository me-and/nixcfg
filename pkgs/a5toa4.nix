{ writeCheckedShellApplication, texlive }:
writeCheckedShellApplication {
  name = "a5toa4";
  runtimeInputs = [ texlive.pkgs.pdfjam.out ];
  text = ''
    landscape=
    input=
    output=

    while (( $# > 0 )); do
      case "$1" in
        -l|--landscape)
          landscape=YesPlease
          shift
          ;;
        -o|--output)
          output="$2"
          shift 2
          ;;
        -l*)
          set -- "-''${1: 1:1}" "-''${1: 2}" "''${@: 2}"
          ;;
        -o*)
          set -- "-''${1: 1:1}" "''${1: 2}" "''${@: 2}"
          ;;
        --output=*)
          set -- "''${1%%=*}" "''${1#*=}" "''${@: 2}"
          ;;
        --)
          if [[ "$input" ]]; then
            exit 64 # EX_USAGE
          elif (( $# != 2 )); then
            exit 64 # EX_USAGE
          fi
          input="$2"
          shift 2
          ;;
        *)
          if [[ "$input" ]]; then
            exit 64 # EX_USAGE
          fi
          input="$1"
          shift
          ;;
      esac
    done

    if [[ -z "$output" ]]; then
      output="''${input%.pdf}-2up.pdf"
    fi

    if [[ "$landscape" ]]; then
      pdfjam "$input" "$input" --nup 2x1 --landscape --outfile "$output"
    else
      pdfjam "$input" "$input" --nup 1x2 --outfile "$output"
    fi
  '';
}
