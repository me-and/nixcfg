{lib, ...}: let
  thisDir = ./.;
  thisDirFilenames = builtins.attrNames (builtins.readDir thisDir);
  toImport = builtins.filter (n: n != "default.nix") thisDirFilenames;
in {
  imports = map (n: lib.path.append thisDir n) toImport;
}
