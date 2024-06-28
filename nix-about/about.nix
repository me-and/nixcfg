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
    lib.strings.concatImapStringsSep "\n" (line: s:
      if line == 1
      then s
      else "    " + s)
    lines;
  noTrailingNewline = lib.strings.removeSuffix "\n";
  formatLong = s: indentAfterFirst (noTrailingNewline s);
  outputLines =
    [
      "Package: ${p.pname}"
      "Version: ${p.version}"
      "Description: ${p.meta.description}"
      (
        if ((builtins.typeOf p.meta.license) == "list")
        then
          (
            if (builtins.length p.meta.license) == 1
            then "License: "
            else "Licenses: "
          )
          + (lib.strings.concatStringsSep " / " (map (l: l.fullName or l) p.meta.license))
        else p.meta.license.fullName or p.meta.license or "Unspecified"
      )
    ]
    ++ (
      lib.optional
      (p.meta ? longDescription)
      "Long description: ${formatLong p.meta.longDescription}"
    )
    ++ (
      lib.optional
      (p.meta ? homepage)
      "Website: ${p.meta.homepage}"
    );
in {
  output =
    if p == null
    then "No package ${pkgname} found\n"
    else (lib.strings.concatStringsSep "\n" outputLines) + "\n";
}
