final: prev:
let
  inherit (final) lib;

  npb = prev.npb.overrideAttrs (
    finalAttrs: prevAttrs: {
      version = "1.1.0";
      src = prevAttrs.src.overrideAttrs {
        hash = "sha256-CL8jRHuJtXFcSh+r8DBtSz9s5xZzU4jwlZygGHeBR6I=";
      };
      cargoDeps = final.rustPlatform.fetchCargoVendor {
        inherit (finalAttrs) pname version src;
        hash = "sha256-LxWhP6NM+lUsUf13x5troFx0k5QHDz2tHOs/3vLGY48=";
      };
    }
  );
in
{
  npb =
    lib.warnIf (lib.versionAtLeast prev.npb.version npb.version) "possibly unnecessary npb overlay"
      npb;
}
