# https://github.com/risicle/nix-heuristic-gc/pull/12
final: prev:
let
  inherit (final) fetchFromGitHub;
  inherit (final.lib.strings) versionAtLeast;
in
{
  nix-heuristic-gc = prev.nix-heuristic-gc.overrideAttrs (
    prevAttrs:
    let
      version = "0.6.2-unstable-2025-11-02";
    in
    {
      version =
        assert versionAtLeast version prevAttrs.version;
        version;
      src = fetchFromGitHub {
        owner = "risicle";
        repo = "nix-heuristic-gc";
        rev = "f5f806607a1d4498b2c17d00b4c83be8b82df3b1";
        hash = "sha256-dn67aeRnjbnzmppfjD/9i6cKvzEywDxTBJzAEdXw93M=";
      };
    }
  );
}
