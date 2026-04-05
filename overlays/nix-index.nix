# https://github.com/NixOS/nixpkgs/pull/507059
final: prev: {
  nix-index-unwrapped =
    if final.lib.versionAtLeast prev.nix-index-unwrapped.version "0.1.9-unstable-2026-03-30" then
      final.lib.warn "unnecessary nix-index overlay" prev.nix-index-unwrapped
    else
      prev.nix-index-unwrapped.overrideAttrs (
        finalAttrs: prevAttrs: {
          version = "0.1.9-unstable-2026-03-30";

          src = final.fetchFromGitHub {
            inherit (prevAttrs.src) owner repo;
            rev = "6e6ec6ffd9c318f5bce0f891eeaab0e89d1f12eb";
            hash = "sha256-Z5IWhtoaU9gNsE8IWO9lWg2O9mjSgMCF3LpPR/YAwGI=";
          };

          cargoHash = "sha256-1M8ICkju2M9CNiRoMkeUveINmF7LmeCP0vuu+haJ+kI=";
          cargoDeps = final.rustPlatform.fetchCargoVendor {
            inherit (finalAttrs) src;
            name = "${finalAttrs.pname}-${finalAttrs.version}";
            hash = finalAttrs.cargoHash;
          };
        }
      );
}
