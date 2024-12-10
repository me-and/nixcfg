{
  requireFile,
  runCommandLocal,
}: let
  fontTarball = requireFile {
    name = "Albertus.tar.xz";
    message = ''
      Please add Albertus.tar.xz to the Nix store manually using
        nix-store --add-fixed sha1 Albertus.tar.xz
    '';
    sha1 = "3f9d0a8ffd2b0627f9c2279fcc8f7146a64997a5";
  };
in
  runCommandLocal "albertus-fonts" {} ''
    mkdir -p "$TMPDIR"/unpack
    cd "$TMPDIR"/unpack
    unpackFile ${fontTarball}
    cd Albertus
    mkdir -p "$out"/share/fonts/truetype
    for f in *; do
        mv "$f" "$out/share/fonts/truetype/''${f// /-}"
    done
  ''
