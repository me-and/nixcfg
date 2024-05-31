{ pkgs ? import <nixpkgs> {}, lib ? pkgs.lib, pkgname }:
let
  p = pkgs."${pkgname}";
  indentAfterFirst = s:
    let lines = lib.strings.splitString "\n" s;
    in
    lib.strings.concatImapStringsSep "\n" (line: s: if line == 1 then s else "    " + s) lines;
  noTrailingNewline = lib.strings.removeSuffix "\n";
  formatLong = s: indentAfterFirst (noTrailingNewline s);
  outputLines = [
    "Package: ${p.name}"
    "Description: ${p.meta.description}"
  ]
  ++ lib.optional (p.meta ? longDescription) "Long description: ${formatLong p.meta.longDescription}"
  ++ lib.optional (p.meta ? homepage) "Website: ${p.meta.homepage}"
  ;

in {
  output = (lib.strings.concatStringsSep "\n" outputLines) + "\n";
}
