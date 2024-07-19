{
  writeShellApplication,
  nix-index,
}:
writeShellApplication {
  name = "nix-locate-bin";
  text = ''
    ${nix-index}/bin/nix-locate \
        --minimal \
        --no-group \
        --type x --type s \
        --top-level \
        --whole-name \
        --at-root \
        "/bin/$1"
  '';
}
