# https://github.com/NixOS/nixpkgs/pull/589961
final: prev:
let
  inherit (final) lib;

  patchedPackages = {
    nginxStable = prev.nginxStable.overrideAttrs (
      finalAttrs: prevAttrs: {
        version = "1.30.7";
        src = final.fetchurl {
          url = "https://nginx.org/download/nginx-${finalAttrs.version}.tar.gz";
          hash = "sha256-JWW1yDcFDpWPcPsPc8SOK8pFQq00n9NW9G+wxyYQvG4=";
        };
      }
    );
    nginxMainline = prev.nginxMainline.overrideAttrs (
      finalAttrs: prevAttrs: {
        version = "1.31.9";
        src = final.fetchurl {
          url = "https://nginx.org/download/nginx-${finalAttrs.version}.tar.gz";
          hash = "sha256-oRxe7uLiV/RHjw5kn4SwBAeH0nfS0+UjOVKqa23LgK0=";
        };
      }
    );
  };
in
builtins.mapAttrs (
  name: pkg:
  if lib.versionAtLeast prev.${name}.version pkg.version then
    lib.warn "unnecessary nginx overlay" prev.${name}
  else
    pkg
) patchedPackages
