final: prev: let
  inherit (final) lib runCommandLocal systemd;
in {
  escapeSystemdPath = str:
    lib.strings.fileContents (
      runCommandLocal "escape" {}
      "${systemd}/bin/systemd-escape -p ${lib.strings.escapeShellArg str} >$out"
    );
}
