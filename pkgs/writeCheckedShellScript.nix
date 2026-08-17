# I wanted a combination of nixpkgs' writeShellScript and
# writeShellApplication, with the former's ability to write files in the root
# of the Nix store rather than putting them in an (often unnecessary for my
# purposes) bin directory, and the latter's ability to do some safety checks on
# the result.  This is that function.
{
  lib,
  runtimeShell,
  writeTextFile,
  stdenv,
  shellcheck-minimal,
}:
let
  runtimeShell' = runtimeShell;
in
lib.makeOverridable (
  {
    name,
    text,
    runtimeInputs ? [ ],
    runtimeEnv ? { },
    runtimeShell ? runtimeShell',
    checkPhase ? null,
    doShellCheck ? lib.meta.availableOn stdenv.buildPlatform shellcheck-minimal.compiler,
    excludeShellChecks ? [ "SC2016" ],
    optionalShellChecks ? [
      "check-extra-masked-returns"
      "check-set-e-suppressed"
      "deprecate-which"
      "require-double-brackets"
      "quote-safe-variables"
    ],
    extraShellCheckFlags ? [ ],
    bashOptions ? [
      "errexit"
      "nounset"
      "pipefail"
    ],
    purePath ? false,
    ...
  }@args:
  let
    passthruAttrs = removeAttrs args [
      "name"
      "text"
      "runtimeInputs"
      "runtimeEnv"
      "runtimeShell"
      "checkPhase"
      "doShellCheck"
      "excludeShellChecks"
      "optionalShellChecks"
      "extraShellCheckFlags"
      "bashOptions"
      "purePath"
    ];
  in
  writeTextFile (
    passthruAttrs
    // {
      inherit name;

      executable = true;

      text =
        let
          setArgs = lib.concatMap (opt: [
            "-o"
            opt
          ]) bashOptions;
        in
        ''
          #!${runtimeShell}
        ''
        + lib.optionalString (bashOptions != [ ]) ''
          set ${lib.escapeShellArgs setArgs}
        ''
        + lib.concatStrings (
          lib.mapAttrsToList (name: value: ''
            ${lib.toShellVar name value}
            export ${name}
          '') runtimeEnv
        )
        + lib.optionalString purePath ''
          export PATH=
        ''
        + lib.optionalString (runtimeInputs != [ ]) ''
          export PATH=${lib.makeBinPath runtimeInputs}''${PATH:+:$PATH}
        ''
        + ''
          ${text}
        '';

      checkPhase =
        let
          excludeFlags = lib.optionals (excludeShellChecks != [ ]) [
            "--exclude"
            (lib.concatStringsSep "," excludeShellChecks)
          ];
          optionalFlags = lib.optionals (optionalShellChecks != [ ]) [
            "--enable"
            (lib.concatStringsSep "," optionalShellChecks)
          ];
        in
        if checkPhase == null then
          ''
            runHook preCheck
            ${stdenv.shellDryRun} "$target"
          ''
          + lib.optionalString doShellCheck ''
            ${lib.getExe shellcheck-minimal} ${
              lib.escapeShellArgs (excludeFlags ++ optionalFlags ++ extraShellCheckFlags)
            } "$target"
          ''
          + ''
            runHook postCheck
          ''
        else
          checkPhase;
    }
  )
)
