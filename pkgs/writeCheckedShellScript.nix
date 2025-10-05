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
}: let
  runtimeShell' = runtimeShell;
in
  {
    name,
    text,
    runtimeInputs ? [],
    runtimeEnv ? {},
    runtimeShell ? runtimeShell',
    meta ? {},
    checkPhase ? null,
    excludeShellChecks ? ["SC2016"],
    optionalShellChecks ? [
      "check-extra-masked-returns"
      "check-set-e-suppressed"
      "deprecate-which"
      "require-double-brackets"
      "quote-safe-variables"
    ],
    extraShellCheckFlags ? [],
    bashOptions ? ["errexit" "nounset" "pipefail"],
    derivationArgs ? {},
    destination ? "",
    purePath ? false,
  }: let
    shellcheckSupported = lib.meta.availableOn stdenv.buildPlatform shellcheck-minimal.compiler;
  in
    writeTextFile {
      inherit name meta destination derivationArgs;
      executable = true;

      text =
        ''
          #!${runtimeShell}
        ''
        + lib.optionalString (bashOptions != []) ''
          shopt -so ${lib.escapeShellArgs bashOptions}
        ''
        + lib.concatStrings (lib.mapAttrsToList (name: value: ''
            ${lib.toShellVar name value}
            export ${name}
          '')
          runtimeEnv)
        + lib.optionalString purePath ''
          export PATH=
        ''
        + lib.optionalString (runtimeInputs != []) ''
          export PATH=${lib.makeBinPath runtimeInputs}''${PATH:+:$PATH}
        ''
        + ''
          ${text}
        '';

      checkPhase = let
        excludeFlags = lib.optionals (excludeShellChecks != []) ["--exclude" (lib.concatStringsSep "," excludeShellChecks)];
        optionalFlags = lib.optionals (optionalShellChecks != []) ["--enable" (lib.concatStringsSep "," optionalShellChecks)];
      in
        if checkPhase == null
        then
          ''
            runHook preCheck
            ${stdenv.shellDryRun} "$target"
          ''
          + lib.optionalString shellcheckSupported ''
            ${lib.getExe shellcheck-minimal} ${lib.escapeShellArgs (excludeFlags ++ optionalFlags ++ extraShellCheckFlags)} "$target"
          ''
          + ''
            runHook postCheck
          ''
        else checkPhase;
    }
