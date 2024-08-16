# When building, use the overlays in the local directory rather than any from
# the environment.
{lib, ...}: let
  overlayInfo = import ../../lib/overlays.nix {inherit lib;};
in {
  nixpkgs.overlays = overlayInfo.overlays;
}
