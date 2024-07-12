{lib, ...}: let overlayDir = ../../overlays; in {
  nixpkgs.overlays = let
    overlayDirContents = builtins.readDir overlayDir;
    overlayDirImportableContents = 
      let importable = n: v: v == "directory" || (builtins.match ".*\\.nix" n) != null;
      in lib.filterAttrs importable overlayDirContents;
      overlayNames = builtins.attrNames overlayDirImportableContents;
      overlayPaths = builtins.map (n: lib.path.append overlayDir n) overlayNames;
      in builtins.map import overlayPaths;
      }
