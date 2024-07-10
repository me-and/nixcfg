# I wanted a combination of nixpkgs' writeShellScript and
# writeShellApplication, with the former's ability to write files in the root
# of the Nix store rather than putting them in an (often unnecessary for my
# purposes) bin directory, and the latter's ability to do some safety cheks on
# the result.  This is that function.
{
  lib,
  writeTextFile,
  runtimeShell,
  stdenv,
  shellcheck-minimal,
}: {
  name,
  text,
  runtimeInputs ? [],
  runtimeEnv ? {},
  meta ? {},
  checkPhase ? null,
  excludeShellChecks ? [],
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
}:
writeTextFile {
  inherit name meta derivationArgs;
  executable = true;
  allowSubstitutes = true;
  preferLocalBuild = false;
  text =
    ''
      #!${runtimeShell}
    ''
    + lib.optionalString (bashOptions != []) ''
      set -o ${lib.escapeShellArgs bashOptions}
    ''
    + lib.concatStrings (lib.mapAttrsToList (name: value: ''
        ${lib.toShellVar name value}
        export ${name}
      '')
      runtimeEnv)
    + lib.optionalString (runtimeInputs != []) ''
      export PATH=${lib.makeBinPath runtimeInputs}:$PATH
    ''
    + ''
      ${text}
    '';
  checkPhase = let
    shellcheckSupported = lib.meta.availableOn stdenv.buildPlatform shellcheck-minimal.compiler;
    excludeFlags = lib.optionals (excludeShellChecks != []) ["--exclude" (lib.concatStringsSep "," excludeShellChecks)];
    optionalFlags = lib.optionals (optionalShellChecks != []) ["--enable" (lib.concatStringsSep "," optionalShellChecks)];
  in
    if checkPhase == null
    then ''
      runHook preCheck
      ${stdenv.shellDryRun} "$target"
      ${lib.getExe shellcheck-minimal} ${lib.escapeShellArgs (excludeFlags ++ optionalFlags ++ extraShellCheckFlags)} "$target"
      runHook postCheck
    ''
    else checkPhase;
}
