{lib, ...}: let
  overlayDir = ../../overlays;
  overlayFiles =
    lib.attrsets.mapAttrsToList
    (name: value: lib.path.append overlayDir name)
    (builtins.readDir overlayDir);
in {
  # When building, use the overlays in the local directory rather than any from
  # the environment.
  nixpkgs.overlays = map import overlayFiles;
}
