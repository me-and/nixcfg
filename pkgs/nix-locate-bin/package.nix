{
  lib,
  writeCheckedShellApplication,
  nix-index,
}:
let
  # https://github.com/NixOS/nixpkgs/issues/444284
  nix-indexVersion = lib.strings.getVersion nix-index;
  topLevelArg =
    if lib.versionOlder nix-indexVersion "0.1.9"
    then "--top-level"
    else "";
in
writeCheckedShellApplication {
  name = "nix-locate-bin";
  text = ''
    exec ${nix-index}/bin/nix-locate \
        --minimal \
        --no-group \
        --type x --type s \
        ${topLevelArg} \
        --whole-name \
        --at-root \
        "/bin/$1"
  '';
}
