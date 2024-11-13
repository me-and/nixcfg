{
  pkgs ? import <nixpkgs> {},
  lib ? pkgs.lib,
  pkgnames,
}: let
  pkgReport = pkgname: let
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

    boolToYN = b:
      if b
      then "Yes"
      else "No";

    outputValues = {
      # Output that will always appear and therefore must have a fallback if the
      # value isn't specified.
      Attribute = pkgname;
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
      Available = boolToYN p.meta.available;
      Broken = boolToYN p.meta.broken;
      Insecure = boolToYN p.meta.insecure;
      Definition = p.meta.position;
      Unsupported = boolToYN p.meta.unsupported;
      Path = p.outPath;
      Paths = lib.concatStrings (map (k: "\n    ${k}: ${p."${k}".outPath}") p.outputs);
    };

    outputSections = (
      [
        "Attribute"
        "Package"
        "Version"
      ]
      ++ (lib.optional (p ? meta && p.meta ? available && p.meta.available != true) "Available")
      ++ (lib.optional (p ? meta && p.meta ? broken && p.meta.broken != false) "Broken")
      ++ (lib.optional (p ? meta && p.meta ? insecure && p.meta.insecure != false) "Insecure")
      ++ (lib.optional (p ? meta && p.meta ? unsupported && p.meta.unsupported != false) "Unsupported")
      ++ ["Description"]
      ++ (lib.optional (p ? meta && p.meta ? longDescription) "Long description")
      ++ ["License"]
      ++ (lib.optional (p ? meta && p.meta ? homepage) "Website")
      ++ (lib.optional (p ? meta && p.meta ? position) "Definition")
      ++ (lib.optional ((builtins.length p.outputs) == 1) "Path")
      ++ (lib.optional ((builtins.length p.outputs) > 1) "Paths")
    );

    outputLiner = section: "${section}: ${outputValues."${section}"}";

    outputLines = map outputLiner outputSections;
  in
    if p == null
    then "No package ${pkgname} found\n"
    else lib.strings.concatLines outputLines;
in {output = lib.strings.concatLines (map pkgReport pkgnames);}
