let
  config = {
    allowUnfree = true;
    allowInsecurePredicate = _: true;
  };
in
{
  pkgs ? import <nixpkgs> { inherit config; },
  lib ? pkgs.lib,
  pkgnames,
}:
let
  evalStrOrFail =
    str:
    let
      result = builtins.tryEval str;
    in
    if result.success then result.value else "(failed eval)";

  pkgReport =
    pkgname:
    let
      packagePath = lib.strings.splitString "." pkgname;
      p = lib.attrsets.attrByPath packagePath null pkgs;

      indent =
        s:
        let
          lines = lib.strings.splitString "\n" s;
        in
        lib.concatStrings (map (s: "\n    " + s) lines);
      noTrailingNewline = lib.strings.removeSuffix "\n";
      formatLong = s: indent (noTrailingNewline s);

      boolToYN = b: if b then "Yes" else "No";

      outputValues = {
        # Output that will always appear and therefore must have a fallback if the
        # value isn't specified.
        Attribute = pkgname;
        Package = p.pname or (if p ? name then "${p.name} (pname unspecified)" else "Unspecified");
        Version = p.version or "Unspecified";
        Description = p.meta.description or "Unspecified";
        License =
          let
            # Based on lib.licenses.toSPDX, but with human-readable names
            # rather than SPDX identifiers.
            mkBracket =
              x:
              if x.licenseType == "compound" || x.licenseType == "exception" then "(${toName x})" else toName x;
            toName =
              license:
              let
                operator = lib.strings.toLower license.operator;
              in
              if builtins.isList license then
                lib.concatMapStringsSep " / " toName license
              else if license.licenseType == "simple" then
                license.fullName
              else if license.licenseType == "compound" then
                lib.concatMapStringsSep " ${operator} " (x: mkBracket x) license.licenses
              else if license.licenseType == "exception" then
                "${mkBracket license.license} ${operator} ${mkBracket license.exception}"
              else if license.licenseType == "plus" then
                "${mkBracket license.license} or later"
              else
                throw "Unknown license type";
          in
          if p ? meta.license then toName p.meta.license else "Unspecified";
        Maintainers =
          if p.meta.maintainers or [ ] == [ ] then
            "None"
          else
            lib.concatStringsSep ", " (map (m: "@${m.github}") p.meta.maintainers);

        # Output that will only appear if it's defined, and therefore can fail if
        # it's not defined.
        "Long description" = formatLong p.meta.longDescription;
        Website = p.meta.homepage;
        Available = boolToYN p.meta.available;
        Broken = boolToYN p.meta.broken;
        Insecure = boolToYN p.meta.insecure;
        Definition = p.meta.position;
        Unsupported = boolToYN p.meta.unsupported;
        Path = evalStrOrFail p.outPath;
        Paths = lib.concatStrings (map (k: "\n    ${k}: ${evalStrOrFail p."${k}".outPath}") p.outputs);
      };

      outputSections = (
        [
          "Attribute"
          "Package"
          "Version"
        ]
        ++ lib.optional (p.meta.available or true != true) "Available"
        ++ lib.optional (p.meta.broken or false != false) "Broken"
        ++ lib.optional (p.meta.insecure or false != false) "Insecure"
        ++ lib.optional (p.meta.unsupported or false != false) "Unsupported"
        ++ [ "Description" ]
        ++ (lib.optional (p ? meta && p.meta ? longDescription) "Long description")
        ++ [ "License" ]
        ++ lib.optional (p ? meta.homepage) "Website"
        ++ lib.optional (p ? meta.position) "Definition"
        ++ [ "Maintainers" ]
        ++ (lib.optional ((builtins.length p.outputs) == 1) "Path")
        ++ (lib.optional ((builtins.length p.outputs) > 1) "Paths")
      );

      outputLiner = section: "${section}: ${outputValues."${section}"}";

      outputLines = map outputLiner outputSections;
    in
    if p == null then "No package ${pkgname} found\n" else lib.strings.concatLines outputLines;
in
{
  output = lib.strings.concatLines (map pkgReport pkgnames);
}
