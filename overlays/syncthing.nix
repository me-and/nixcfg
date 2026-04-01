# https://github.com/NixOS/nixpkgs/issues/502836
# https://github.com/NixOS/nixpkgs/pull/458464
final: prev:
let
  inherit (final) lib;
  overrideSyncthing =
    syncthing:
    if lib.versionAtLeast syncthing.version "2.0.15" then
      lib.warn "unnecessary syncthing overlay" syncthing
    else
      syncthing.overrideAttrs (
        finalAttrs: prevAttrs: {
          version = "2.0.15";
          src = final.fetchFromGitHub {
            inherit (prevAttrs.src) owner repo;
            tag = "v${finalAttrs.version}";
            hash = "sha256-v77ovjV+UoCRA1GteP+HDqC8dsRvtOhFX/IkSgSIf8Y=";
          };
          vendorHash = "sha256-boYTLgvH+iWlh3y3Z0LPvSVGEget3X94AthtJKphhCw=";

          # https://github.com/NixOS/nixpkgs/pull/505674
          # In particular, I want to be able to evaluate the aarch64 tests on
          # x86_64 and vice versa, and the IFD that this test currently uses
          # means that fails.
          passthru = prevAttrs.passthru // {
            tests = builtins.removeAttrs prevAttrs.passthru.tests [ "syncthing-folders" ];
          };
        }
      );
in
{
  syncthing = overrideSyncthing prev.syncthing;
  syncthing-discovery = overrideSyncthing prev.syncthing-discovery;
  syncthing-relay = overrideSyncthing prev.syncthing-relay;
}
