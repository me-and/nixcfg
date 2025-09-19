{
  writeCheckedShellApplication,
  nix-index,
}:
writeCheckedShellApplication {
  name = "nix-locate-bin";
  text = ''
    exec ${nix-index}/bin/nix-locate \
        --minimal \
        --no-group \
        --type x --type s \
        --whole-name \
        --at-root \
        "/bin/$1"
  '';
}
