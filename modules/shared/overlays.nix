{lib, ...}: let
  # TODO Remove duplication of the below in modules/home-manager/overlays.nix
  thisRepoCleaned = lib.sources.cleanSourceWith {
    src = ../../.;
    # Filter out:
    # - All hidden files, including but not limited to the .git directory
    # - Any symlinks, as they're almost certainly symlinks to Nix build results
    # - The secrets directory, as that should never make it into the Nix store
    filter = path: type: let
      baseName = builtins.baseNameOf path;
    in
      (type != "symlink")
      && (baseName != "secrets")
      && ((builtins.match "\\..*" baseName) == null);
    name = "nixcfg";
  };
  overlayDir = "${thisRepoCleaned}/overlays";
  overlayFiles =
    lib.attrsets.mapAttrsToList
    (name: value: "${overlayDir}/${name}")
    (builtins.readDir overlayDir);
in {
  # When building, use the overlays in the local directory rather than any from
  # the environment.
  nixpkgs.overlays = map import overlayFiles;
}
