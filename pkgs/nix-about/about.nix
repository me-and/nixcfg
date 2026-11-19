let
  config = {
    allowUnfree = true;
    allowInsecurePredicate = _: true;
  };
in
{
  pkgsPath ? null,
  flake ? null,
  pkgnames,
}:
assert flake != null -> pkgsPath == null;
let
  pkgs =
    if flake == null && pkgsPath == null then
      import <nixpkgs> { inherit config; }
    else if pkgsPath != null then
      import pkgsPath { inherit config; }
    else
      import (builtins.getFlake flake) { inherit config; };

  # Always import the local lib rather than picking it up from pkgs: we want
  # the method by which the report is built to depend on the local system, not
  # any specified nixpkgs argument.
  #
  # TODO This approach depends on the environment (specifically NIX_PATH) that
  # the script is run under, and should probably instead reference the lib from
  # the nixpkgs used to build this package in the name of having more
  # deterministic output.
  lib = import <nixpkgs/lib>;

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
              let
                type = x.licenseType or "";
              in
              if type == "compound" || type == "exception" then "(${toName x})" else toName x;
            toName =
              license:
              let
                operator = lib.strings.toLower license.operator;
              in
              if builtins.isList license then
                lib.concatMapStringsSep " / " toName license
              else if builtins.isString license then
                license
              else if license.licenseType or "simple" == "simple" then
                license.fullName or "Unknown license type"
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
          let
            teamMaintainers = lib.flatten (map (builtins.getAttr "members") p.meta.teams or [ ]);
            individualMaintainers = p.meta.maintainers or [ ];
            maintainerHandles = lib.uniqueStrings (
              map (builtins.getAttr "github") (teamMaintainers ++ individualMaintainers)
            );
          in
          if maintainerHandles == [ ] then
            "None"
          else
            lib.concatStringsSep ", " (map (m: "@${m}") maintainerHandles);

        # Output that will only appear if it's defined, and therefore can fail if
        # it's not defined.
        "Long description" = formatLong p.meta.longDescription;
        Website = p.meta.homepage;
        Available = boolToYN p.meta.available;
        Broken = boolToYN p.meta.broken;
        Insecure = boolToYN p.meta.insecure;
        Definition = p.meta.position;
        Unsupported = boolToYN p.meta.unsupported;
        Path = evalStrOrFail p.${builtins.head p.outputs or [ "out" ]}.outPath;
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
        ++ (lib.optional ((builtins.length p.outputs or [ "out" ]) == 1) "Path")
        ++ (lib.optional ((builtins.length p.outputs or [ "out" ]) > 1) "Paths")
      );

      outputLiner = section: "${section}: ${outputValues."${section}"}";

      outputLines = map outputLiner outputSections;
    in
    if p == null then "No package ${pkgname} found\n" else lib.strings.concatLines outputLines;
in
{
  output = lib.strings.concatLines (map pkgReport pkgnames);
}
