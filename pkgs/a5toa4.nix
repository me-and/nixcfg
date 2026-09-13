{ writeCheckedShellApplication, texlive }:
writeCheckedShellApplication {
  name = "a5toa4";
  runtimeInputs = [ texlive.pkgs.pdfjam.out ];
  text = ''
    landscape=
    input=
    output=

    help () {
      echo 'a5toa4 [options] [--] <input-file>'
      echo
      echo 'Impose an A5 PDF document to be printed twice on a single sheet of A4.'
      echo
      echo 'Options:'
      echo
      echo '  -l|--landscape:'
      echo '    Impose a portrait A5 document onto a landscape A4 document, rather than'
      echo '    the default of imposing a landscape A5 document onto a portrait A4'
      echo '    document.'
      echo '  -o|--output <output-file>'
      echo '    Specify the output filename (default `<input>-2up.pdf`)'
      echo '  -h|--help'
      echo '    Output this help message'
    }

    fail_usage () {
      printf "%s\n" "$1" >&2
      echo 'specify `--help` for usage instructions' >&2
      exit 64 # EX_USAGE
    }

    while (( $# > 0 )); do
      case "$1" in
        -h|--help)
          help
          exit 0
          ;;
        -l|--landscape)
          landscape=YesPlease
          shift
          ;;
        -o|--output)
          output="$2"
          shift 2
          ;;
        -[hl]*)
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
            fail_usage "multiple input files specified: $input and $2"
          elif (( $# != 2 )); then
            fail_usage "multiple input files specified: $2 and $3"
          fi
          input="$2"
          shift 2
          ;;
        --*)
          fail_usage "unexpected option: ''${1%%=*}"
          ;;
        -*)
          fail_usage "unexpected option: ''${1:0:2}"
          ;;
        *)
          if [[ "$input" ]]; then
            fail_usage "multiple input files specified: $input and $1"
          fi
          input="$1"
          shift
          ;;
      esac
    done

    if [[ -z "$output" ]]; then
      if [[ "$input" = /dev/stdin ]]; then
        output=2up.pdf
      else
        output="''${input%.pdf}-2up.pdf"
      fi
    fi

    if [[ "$landscape" ]]; then
      pdfjam "$input" "$input" --nup 2x1 --landscape --outfile "$output"
    else
      pdfjam "$input" "$input" --nup 1x2 --outfile "$output"
    fi
  '';
}
