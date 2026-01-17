{
  lib,
  ansi2,
  mailutils,
  coreutils,
  system-sendmail,
  perlPackages,
  substCheckedShellApplication,
  runtimeShell,
}:
let
  runtimeDeps = [
    perlPackages.mimeConstruct
    ansi2
    mailutils
    coreutils
    system-sendmail
  ];
in
substCheckedShellApplication {
  name = "colourmail";
  src = ./colourmail.sh;
  substitutions = {
    inherit runtimeShell;
    PATH = lib.makeBinPath runtimeDeps;
  };
}
