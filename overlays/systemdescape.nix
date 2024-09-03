final: prev: let
  inherit (final) lib runCommandLocal systemd;
in {
  escapeSystemdString = str:
    lib.strings.fileContents (
      runCommandLocal "escape" {}
      "${systemd}/bin/systemd-escape ${lib.strings.escapeShellArg str} >$out"
    );
  escapeSystemdPath = str:
    lib.strings.fileContents (
      runCommandLocal "escape" {}
      "${systemd}/bin/systemd-escape -p ${lib.strings.escapeShellArg str} >$out"
    );
}
