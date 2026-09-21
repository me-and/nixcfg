{
  lib,
  writeCheckedShellApplication,
  coreutils,
  nix,
  jq,
  nix-eval-jobs,
  nix-add-drv-root,
  stdenv,
}:
writeCheckedShellApplication {
  name = "nix-run-available-checks";
  runtimeInputs = [
    coreutils
    nix
    jq
    nix-eval-jobs
    nix-add-drv-root
  ];
  text = ''
    system=${lib.escapeShellArg stdenv.hostPlatform.system}
    features_str="$(nix config show system-features)"

    exclude_cache=Yes
    github=
    extra_realisation_args=()
    extra_eval_args=()
    build=Yes
    drv_root=
    max_eval_memory=
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
        --add-drv-root)
            drv_root="$2"
            shift 2
            ;;
        --add-drv-root=*)
            drv_root="''${1#--add-drv-root=}"
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
        --max-memory-size)
            max_eval_memory="$2"
            shift 2
            ;;
        --max-memory-size=*)
            max_eval_memory="''${1#--max-memory-size=}"
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

    if [[ "$max_eval_memory" ]]; then
        extra_eval_args+=(--max-memory-size "$max_eval_memory")
    else
        # The 4GB default isn't sufficient for evaluating some of my
        # configurations :(
        extra_eval_args+=(--max-memory-size "$((8*1024))")
    fi

    # shellcheck disable=SC2312 # exit code handled with `wait "$!"`
    mapfile -d "" -t drvs_to_realise < <(
        nix-eval-jobs \
          --flake \
          --meta \
          "''${extra_eval_args[@]}" \
          .#checks."$system" |
        jq --from-file ${./filter.jq} \
          --arg features_str "$features_str" \
          --arg system "$system" \
          --arg github "$github" \
          --raw-output0
    )
    wait "$!"

    if [[ "$build" ]]; then
      if [[ "$drv_root" ]]; then
          :
      elif [[ -v RUNTIME_DIRECTORY ]]; then
          derivation_dir="$RUNTIME_DIRECTORY"/derivations
          mkdir -p -- "$derivation_dir"
          drv_root="$derivation_dir"/result
      else
          tmpdir="$(mktemp -d --tmpdir nix-run-available-checks.$$.XXXXX)"
          trap 'rm -rf -- "$tmpdir"' EXIT
          derivation_dir="$tmpdir/derivations"
          mkdir -p -- "$derivation_dir"
          drv_root="$derivation_dir"/result
      fi

      # Avoid any mistimed garbage collections deleting things while we're
      # mid-build.
      nix-add-drv-root --root "$drv_root" "''${drvs_to_realise[@]}"

      if command -v nom >/dev/null; then
          nix-store --realise "''${extra_realisation_args[@]}" --log-format internal-json -v "''${drvs_to_realise[@]}" |& nom --json
      else
          nix-store --realise "''${extra_realisation_args[@]}" "''${drvs_to_realise[@]}"
      fi
    else
      if [[ "$drv_root" ]]; then
          nix-add-drv-root --root "$drv_root" "''${drvs_to_realise[@]}"
      fi
      printf '%s\n' "''${drvs_to_realise[@]}"
    fi
  '';
}
