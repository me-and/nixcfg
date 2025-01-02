# I wanted a combination of nixpkgs' writeShellScript and
# writeShellApplication, with the former's ability to write files in the root
# of the Nix store rather than putting them in an (often unnecessary for my
# purposes) bin directory, and the latter's ability to do some safety checks on
# the result.  This is that function.
final: prev: let
  inherit (final) lib writeTextFile runtimeShell stdenv shellcheck-minimal;

  defaultExcludeShellChecks = ["SC2016"];
  defaultOptionalShellChecks = [
    "check-extra-masked-returns"
    "check-set-e-suppressed"
    "deprecate-which"
    "require-double-brackets"
    "quote-safe-variables"
  ];
  defaultExtraShellCheckFlags = [];

  shellcheckSupported = lib.meta.availableOn stdenv.buildPlatform shellcheck-minimal.compiler;
in {
  writeCheckedShellScript = {
    name,
    text,
    runtimeInputs ? [],
    runtimeEnv ? {},
    meta ? {},
    checkPhase ? null,
    excludeShellChecks ? defaultExcludeShellChecks,
    optionalShellChecks ? defaultOptionalShellChecks,
    extraShellCheckFlags ? defaultExtraShellCheckFlags,
    bashOptions ? ["errexit" "nounset" "pipefail"],
    derivationArgs ? {},
    destination ? "",
    purePath ? false,
  }:
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
    };

  writeCheckedShellApplication = args: final.writeCheckedShellScript ({destination = "/bin/${args.name}";} // args);

  # pkgs.substitute, but with shellcheck.
  substCheckedShellScript = {
    name ? null,
    src,
    meta ? {},
    checkPhase ? null,
    excludeShellChecks ? defaultExcludeShellChecks,
    optionalShellChecks ? defaultOptionalShellChecks,
    extraShellCheckFlags ? defaultExtraShellCheckFlags,
    substitutions,
    destination ? "",
  }: let
    name' =
      if name != null
      then name
      else if destination != ""
      then baseNameOf destination
      else baseNameOf src;
    substitutionArgs = builtins.concatLists (final.lib.attrsets.mapAttrsToList (k: v: ["--subst-var-by" k v]) substitutions);
  in
    final.runCommand name'
    {
      checkPhase =
        if checkPhase == null
        then let
          excludeFlags = lib.optionals (excludeShellChecks != []) ["--exclude" (lib.concatStringsSep "," excludeShellChecks)];
          optionalFlags = lib.optionals (optionalShellChecks != []) ["--enable" (lib.concatStringsSep "," optionalShellChecks)];
        in
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
      meta = let
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
    '';

  substCheckedShellApplication = args: let
    name = args.name or (baseNameOf args.src);
  in
    final.substCheckedShellScript ({destination = "/bin/${name}";} // args);
}
