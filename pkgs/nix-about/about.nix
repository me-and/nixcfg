{
  pkgs ? import <nixpkgs> {},
  lib ? pkgs.lib,
  pkgname,
}: let
  packagePath = lib.strings.splitString "." pkgname;
  p = lib.attrsets.attrByPath packagePath null pkgs;

  indentAfterFirst = s: let
    lines = lib.strings.splitString "\n" s;
  in
    lib.strings.concatImapStringsSep "\n"
    (line: s:
      if line == 1
      then s
      else "    " + s)
    lines;
  noTrailingNewline = lib.strings.removeSuffix "\n";
  formatLong = s: indentAfterFirst (noTrailingNewline s);

  outputValues = {
    # Output that will always appear and therefore must have a fallback if the
    # value isn't specified.
    Package =
      p.pname
      or (
        if p ? name
        then "${p.name} (pname unspecified)"
        else "Unspecified"
      );
    Version = p.version or "Unspecified";
    Description = p.meta.description or "Unspecified";
    License = let
      license = p.meta.license or "Unspecified";
      licenseName = l: l.fullName or l;
    in
      if (builtins.typeOf license) == "list"
      then lib.concatStringsSep " / " (map licenseName license)
      else licenseName license;

    # Output that will only appear if it's defined, and therefore can fail if
    # it's not defined.
    "Long description" = formatLong p.meta.longDescription;
    Website = p.meta.homepage;
  };

  outputSections = (
    [
      "Package"
      "Version"
      "Description"
    ]
    ++ (lib.optional (p ? meta && p.meta ? longDescription) "Long description")
    ++ ["License"]
    ++ (lib.optional (p ? meta && p.meta ? homepage) "Website")
  );

  outputLiner = section: "${section}: ${outputValues."${section}"}";

  outputLines = map outputLiner outputSections;
in {
  output =
    if p == null
    then "No package ${pkgname} found\n"
    else (lib.strings.concatStringsSep "\n" outputLines) + "\n";
}
