# https://github.com/NixOS/nixpkgs/issues/502836
final: prev:
let
  inherit (final) lib;

  patch = final.fetchpatch {
    url = "https://github.com/quic-go/quic-go/commit/8bfbd717c8379913493f3d6a80a09eb901420030.patch";
    hash = "sha256-ULNJ7j9/VKHpZK7m2O6jTeXk+xvpED03TE0xPdlAQZ0=";
    stripLen = 1;
    extraPrefix = "vendor/github.com/quic-go/quic-go/";
  };

  overrideSyncthing =
    syncthing:
    syncthing.overrideAttrs (prevAttrs: {
      passthru = prevAttrs.passthru // {
        overrideModAttrs = lib.composeExtensions prevAttrs.passthru.overrideModAttrs (
          finalModAttrs: prevModAttrs: {
            postBuild = ''
              patch -p1 <${patch}
            '';
          }
        );
      };
      vendorHash = "sha256-QTnVVsBDqnpup2PBxTMYh0UkhZ7e2Nh/lF83JU5h6K8=";
    });
in
{
  syncthing = overrideSyncthing prev.syncthing;
  syncthing-discovery = overrideSyncthing prev.syncthing-discovery;
  syncthing-relay = overrideSyncthing prev.syncthing-relay;
}
