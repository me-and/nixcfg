{
  # Get `mosh` from `pkgs`, to avoid picking up the mosh
  # package we're creating here.
  pkgs,
  lib,
  symlinkJoin,
  substCheckedShellApplication,
  runtimeShell,
}:
let
  myMosh = substCheckedShellApplication {
    name = "mosh";
    src = ./mosh.sh;
    substitutions = {
      inherit runtimeShell;
      PATH = lib.makeBinPath [ pkgs.mosh ];
    };
  };
in
symlinkJoin {
  name = "mosh";
  paths = [
    myMosh
    pkgs.mosh
  ];
}
