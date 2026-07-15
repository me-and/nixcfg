{
  lib,
  writeCheckedShellApplication,
  nix,
  jq,
  nix-eval-jobs,
  stdenv,
}:
writeCheckedShellApplication {
  name = "nix-run-available-checks";
  runtimeInputs = [
    nix
    jq
    nix-eval-jobs
  ];
  text = ''
    system=${lib.escapeShellArg stdenv.hostPlatform.system}
    features_str="$(nix config show system-features)"

    exclude_cache=Yes
    github=
    extra_realisation_args=()
    extra_eval_args=()
    build=Yes
    while (( $# > 0 )); do
        case "$1" in
        -a|--all)
            exclude_cache=
            shift
            ;;
        -B|--no-build)
            build=
            shift
            ;;
        -g|--github)
            github=Yes
            shift
            ;;
        -k|--keep-going)
            extra_realisation_args+=(--keep-going)
            shift
            ;;
        --add-root)
            extra_realisation_args+=(--add-root "$2")
            shift 2
            ;;
        --add-root=*)
            extra_realisation_args+=(--add-root "''${1#--add-root=}")
            shift
            ;;
        --override-input)
            extra_eval_args+=("$1" "$2" "$3")
            shift 3
            ;;
        -[aBgk]*)
            set -- "-''${1: 1:1}" "-''${1: 2}" "''${@: 2}"
            ;;
        *)  printf 'unexpected argument: %q\n' "$1" >&2
            exit 64
            ;;
        esac
    done

    if [[ "$exclude_cache" ]]; then
        extra_eval_args+=(--check-cache-status)
    fi

    get_drvs () {
      nix-eval-jobs \
        --flake \
        --meta \
        "''${extra_eval_args[@]}" \
        .#checks."$system" |
      jq --from-file ${./filter.jq} \
        --unbuffered \
        --arg features_str "$features_str" \
        --arg system "$system" \
        --arg github "$github" \
        "$@"
    }

    if [[ "$build" ]]; then
      mapfile -d "" -t drvs_to_realise < <(
        # shellcheck disable=SC2312 # exit code handled with `wait "$!"`
        get_drvs --raw-output0
      )
      wait "$!"

      if command -v nom >/dev/null; then
          nix-store --realise "''${extra_realisation_args[@]}" --log-format internal-json -v "''${drvs_to_realise[@]}" |& nom --json
      else
          nix-store --realise "''${extra_realisation_args[@]}" "''${drvs_to_realise[@]}"
      fi
    else
      get_drvs --raw-output
    fi
  '';
}
