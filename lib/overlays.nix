{lib}: let
  # Filter out:
  # - All hidden files, including but not limited to the .git directory
  # - Any symlinks, as they're almost certainly symlinks to Nix build results
  # - The secrets directory, as that should never make it into the Nix store
  fileFilter = path: type: let
    baseName = builtins.baseNameOf path;
  in
    (type != "symlink")
    && (baseName != "secrets")
    && ((builtins.match "\\..*" baseName) == null);

  storeRepo = lib.sources.cleanSourceWith {
    name = "nixcfg";
    src = ../.;

    filter = fileFilter;
  };
in rec {
  storeOverlayDir = "${storeRepo}/overlays";
  storeOverlayFiles = let
    filenames = builtins.attrNames (builtins.readDir storeOverlayDir);
  in
    map (n: "${storeOverlayDir}/${n}") filenames;

  overlayDir = ../overlays;
  overlayFiles = let
    filenames =
      builtins.attrNames
      (lib.filterAttrs fileFilter (builtins.readDir overlayDir));
  in
    map (n: lib.path.append overlayDir n) filenames;
  overlays = map import overlayFiles;
}
