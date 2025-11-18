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

    nix-eval-jobs --flake --check-cache-status .#checks."$system" |
        jq --from-file ${./filter.jq} \
            --raw-output0 \
            --arg features_str "$features_str" \
            --arg system "$system" |
        mapfile -d "" -t drvs_to_realise

    nix-store --realise "''${drvs_to_realise[@]}"
  '';
}
