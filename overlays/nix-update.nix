# https://github.com/NixOS/nixpkgs/pull/591736
# https://github.com/Mic92/nix-update/pull/698
final: prev:
let
  inherit (final) lib;

  nix-update = prev.nix-update.overridePythonAttrs (prevAttrs: {
    version = "1.17.0";

    src = prevAttrs.src.override { hash = "sha256-TCOhUWb53V3nrJRD3JuADly1U9fNi0Z79QMcjhbefHg="; };

    build-system = [ final.python3Packages.hatchling ];

    dependencies = [ final.python3Packages.ast-grep-py ];
  });
in
{
  nix-update =
    if lib.versionAtLeast prev.nix-update.version nix-update.version then
      lib.warn "unnecessary nix-update overlay" prev.nix-update
    else
      nix-update;
}
