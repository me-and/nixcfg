{ writeShellApplication, nix }:
writeShellApplication {
  name = "nix-about";
  text = ''
    for arg; do
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
