{
  lib,
  escapeSystemdString,
}:
s:
let
  inherit (lib.strings) normalizePath removePrefix removeSuffix;

  trim = s: removeSuffix "/" (removePrefix "/" s);
  normalizedPath = normalizePath s;
in
escapeSystemdString (if normalizedPath == "/" then normalizedPath else trim normalizedPath)
