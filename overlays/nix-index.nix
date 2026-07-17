# https://github.com/NixOS/nixpkgs/pull/537920
final: prev:
let
  lib = final.lib;

  # Just using overrideAttrs gets confused because of how cargoHash is handled.
  nix-index-unwrapped = final.rustPlatform.buildRustPackage (finalAttrs: {
    inherit (prev.nix-index-unwrapped)
      pname
      __structuredAttrs
      nativeBuildInputs
      buildInputs
      postInstall
      doInstallCheck
      meta
      ;
    version = "0.1.11";
    src = prev.nix-index-unwrapped.src.override {
      tag = "v${finalAttrs.version}";
      hash = "sha256-yl/acohrgP0C5w4eozNcWcpCGhmMMjFbzgHsKwXKw00=";
    };
    cargoHash = "sha256-EJbNptLskphe+xfI8oQ0DVUx6y4dO52eeuPiG6FSQbI=";
  });
in
{
  nix-index-unwrapped =
    lib.warnIf (lib.versionAtLeast prev.nix-index-unwrapped.version nix-index-unwrapped.version)
      "possibly unnecessary nix-index overlay"
      nix-index-unwrapped;
}
