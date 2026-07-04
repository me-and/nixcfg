{
  lib,
  nix-output-monitor,
  writeCheckedShellApplication,
}:
writeCheckedShellApplication {
  name = "nom-realise";
  text = ''
    nix-store --realise --log-format internal-json -v "$@" |& ${lib.getExe nix-output-monitor} --json
  '';
}
