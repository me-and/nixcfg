{ writeCheckedShellApplication, coreutils, nix-eval-jobs, jq, moreutils }:
writeCheckedShellApplication {
  name = "test.sh";
  runtimeInputs = [ coreutils nix-eval-jobs jq moreutils ];
  text = ''
    set -x

    workdir="$(mktemp -d)"
    printf '%s\n' "$workdir" >&2

    nix-eval-jobs --no-instantiate . 2>/dev/null | jq -c 'select(has("error") | not)' >"$workdir"/before.jsonl &
    before_eval="$!"

    nix-eval-jobs --no-instantiate --arg overlays '[ (final: prev: { git = prev.git.override { withBreakingChanges = true; }; }) ]' . 2>/dev/null | jq -c 'select(has("error") | not)' >"$workdir"/after.jsonl &
    after_eval="$!"

    wait "$before_eval"
    wait "$after_eval"

    combine "$workdir"/before.jsonl xor "$workdir"/after.jsonl | jq -c '.attrPath' | sort -u
  '';
}
