final: prev:
let
  inherit (final) lib;

  nix-index-unwrapped = prev.nix-index-unwrapped.overrideAttrs (
    finalAttrs: prevAttrs: {
      version = "0.1.11-unstable-2026-10-14";
      src = final.fetchFromGitHub {
        inherit (prevAttrs.src) owner repo;
        rev = "fb369a3ed3a3ea76963757aff508347014c0da35";
        hash = "sha256-JA03qBiTwNRHc/NBS6Vgj2gRmEXW7m+vP+bel6T3ll0=";
      };
      cargoDeps = final.rustPlatform.fetchCargoVendor {
        inherit (finalAttrs) pname version src;
        hash = "sha256-5dc7AazqAnI0wwLTUS5slAP45cwJQMSVRYg6SBlnOao=";
      };

      # Remove versionCheckHook.
      nativeInstallCheckInputs = [ ];
    }
  );
in
{
  nix-index-unwrapped =
    lib.warnIf (lib.versionAtLeast prev.nix-index-unwrapped.version nix-index-unwrapped.version)
      "possibly unnecessary nix-index overlay"
      nix-index-unwrapped;
}
