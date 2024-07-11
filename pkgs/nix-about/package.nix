{
  writeShellApplication,
  nix,
}:
writeShellApplication {
  name = "nix-about";
  text = ''
    first=Yes
    for arg; do
        if [[ "$first" ]]; then
            first=
        else
            echo
        fi
        ${nix}/bin/nix \
            --extra-experimental-features nix-command \
            eval \
            --read-only \
            --argstr pkgname "$arg" \
            --file ${./about.nix} \
            --raw \
            output
    done
  '';
}
