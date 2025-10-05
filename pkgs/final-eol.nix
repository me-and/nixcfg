{
  lib,
  runCommand,
  runtimeShell,
  coreutils,
  vim,
  stdenv,
  shellcheck-minimal,
}: let
  script = {
    onFinalEol,
    noFinalEol,
  }: ''
    #!${runtimeShell}
    shopt -so errexit nounset pipefail

    PATH=${lib.makeBinPath [coreutils vim.xxd]}
    export PATH

    if (( $# == 0 )); then
        echo 'No files specified' >&2
        exit 1
    fi

    rc=0
    for f; do
        final_byte="$(xxd -p -s-1 -- "$f")"
        if [[ "$final_byte" = '0a' ]]; then
            ${onFinalEol}
        else
            ${noFinalEol}
        fi
    done

    exit "$rc"
  '';
  skipCmd = ''
    printf 'Skipped %s\n' "$f" >&2
    rc=1
  '';
in
  runCommand
  "final-eol"
  {
    passAsFile = ["addFinalEol" "rmFinalEol"];
    addFinalEol = script {
      onFinalEol = skipCmd;
      noFinalEol = ''
        printf '\n' >>"$f"
      '';
    };
    rmFinalEol = script {
      onFinalEol = ''
        truncate -s-1 -- "$f"
      '';
      noFinalEol = skipCmd;
    };
    checkPhase = let
      shellcheckSupported = lib.meta.availableOn stdenv.buildPlatform shellcheck-minimal.compiler;
    in
      ''
        runHook preCheck
        for f in "$out"/bin/add-final-eol "$out"/bin/rm-final-eol; do
            ${stdenv.shellDryRun} "$f"
        done
      ''
      + lib.optionalString shellcheckSupported ''
        ${lib.getExe shellcheck-minimal} --exclude SC2016 --enable check-extra-masked-returns,check-set-e-suppressed,deprecate-which,require-double-brackets,quote-safe-variables "$out"/bin/add-final-eol "$out"/bin/rm-final-eol
      ''
      + ''
        runHook postCheck
      '';
    preferLocalBuild = true;
  }
  ''
    mkdir -p "$out"/bin
    mv "$addFinalEolPath" "$out"/bin/add-final-eol
    mv "$rmFinalEolPath" "$out"/bin/rm-final-eol
    chmod +x "$out"/bin/add-final-eol "$out"/bin/rm-final-eol

    eval "$checkPhase"
  ''
