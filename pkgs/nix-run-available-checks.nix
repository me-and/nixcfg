{ lib, writeCheckedShellApplication, jq, nix-eval-jobs, stdenv }:
writeCheckedShellApplication {
  name = "nix-run-available-checks";
  runtimeInputs = [ jq nix-eval-jobs ];
  text = ''
    set -x

    system=${lib.escapeShellArg stdenv.hostPlatform.system}
    features_str="$(nix config show system-features)"

    declare -p system features_str

    nix-eval-jobs --flake --check-cache-status .#checks."$system" |
        jq --arg features_str "$features_str" '
            $features_str / " " as $features
            | select((.requiredSystemFeatures - $features) == [])
            | select(.isCached | not)
        '
  '';
}
