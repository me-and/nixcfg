# Generate an attrset with values being files or folders that can be imported,
# and names being the name of the file/folder with any .nix suffix removed.
{
  lib,
  subdirfiles,
}:
{ __functor = self:
{
  dir,
  excludes ? [ ],
}:
let
  importableDirs = subdirfiles {
    inherit dir excludes;
    filename = "default.nix";
  };

  filenames = lib.filterAttrs (n: v: lib.hasSuffix ".nix" n && !builtins.elem n excludes) (
    builtins.readDir dir
  );
  importableFiles = lib.mapAttrs' (
    n: v: lib.nameValuePair (lib.removeSuffix ".nix" n) (dir + "/${n}")
  ) filenames;
in
  lib.attrsets.unionOfDisjoint importableDirs importableFiles;
  tests = {
    testdoot = { expr = lib.id 1; expected = 1; };
  };
}
