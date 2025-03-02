{lib, ...}: let
  overlayDir = ../../overlays;
  overlayFiles = let
    filenames = builtins.attrNames (builtins.readDir overlayDir);
  in map (n: lib.path.append overlayDir n) filenames;
in {
  nixpkgs.overlays = map import overlayFiles;
}
