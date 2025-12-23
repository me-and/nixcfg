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
    shopt -s lastpipe

    system=${lib.escapeShellArg stdenv.hostPlatform.system}
    features_str="$(nix config show system-features)"

    extra_args=()
    while (( $# > 0 )); do
        case "$1" in
        -k|--keep-going)
            extra_args+=(--keep-going)
            shift
            ;;
        --add-root)
            extra_args+=(--add-root "$2")
            shift 2
            ;;
        --add-root=*)
            extra_args+=(--add-root "''${1#--add-root=}")
            shift
            ;;
        *)  printf 'unexpected argument: %q\n' "$1" >&2
            exit 64
            ;;
        esac
    done

    nix-eval-jobs --flake --check-cache-status .#checks."$system" |
        jq --from-file ${./filter.jq} \
            --raw-output0 \
            --arg features_str "$features_str" \
            --arg system "$system" |
        mapfile -d "" -t drvs_to_realise

    if command -v nom >/dev/null; then
        nix-store --realise "''${extra_args[@]}" --log-format internal-json -v "''${drvs_to_realise[@]}" |& nom --json
    else
        nix-store --realise "''${extra_args[@]}" "''${drvs_to_realise[@]}"
    fi
  '';
}
