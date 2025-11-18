# pkgs.substitute, but with shellcheck.
{
  lib,
  stdenv,
  shellcheck-minimal,
  runCommand,
}:
{
  name ? null,
  src,
  meta ? { },
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
  substitutions,
  destination ? "",
}:
let
  name' =
    if name != null then
      name
    else if destination != "" then
      baseNameOf destination
    else
      baseNameOf src;
  substitutionArgs = builtins.concatLists (
    lib.attrsets.mapAttrsToList (k: v: [
      "--subst-var-by"
      k
      v
    ]) substitutions
  );
in
runCommand name'
  {
    checkPhase =
      if checkPhase == null then
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
    meta =
      let
        matches = builtins.match "/bin/([^/]+)" destination;
      in
      lib.optionalAttrs (matches != null) {
        mainProgram = lib.head matches;
      }
      // meta;
  }
  ''
    target=$out${lib.escapeShellArg destination}
    mkdir -p "$(dirname "$target")"
    substitute ${src} "$target" ${lib.escapeShellArgs substitutionArgs}
    chmod +x "$target"

    eval "$checkPhase"
  ''
