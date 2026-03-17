{
  lib,
  substCheckedShellApplication,
  runtimeShell,
  systemd,
  coreutils,
  util-linux,
}:
substCheckedShellApplication {
  name = "mailsync";
  src = ./mailsync.sh;
  substitutions = {
    inherit runtimeShell;
    PATH = lib.makeBinPath [
      systemd
      coreutils
    ];
  };
}
