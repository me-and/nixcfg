final: prev:
let
  inherit (final) lib;

  npb = prev.npb.overrideAttrs (
    finalAttrs: prevAttrs: {
      version = "1.2.1";
      src = prevAttrs.src.overrideAttrs {
        hash = "sha256-+Cnorizn6rAgNPY5QrPhfplAwcNU0LZbUhq+dCQj/PI=";
      };
      cargoDeps = final.rustPlatform.fetchCargoVendor {
        inherit (finalAttrs) pname version src;
        hash = "sha256-AQ3EqL3NyikwW5ck8xhI7UV3arOZUEjmXFmkkT6WUGA=";
      };
    }
  );
in
{
  npb =
    lib.warnIf (lib.versionAtLeast prev.npb.version npb.version) "possibly unnecessary npb overlay"
      npb;
}
