final: prev: let
  inherit (final) lib runCommandLocal systemd;
  inherit (final.lib) replaceStrings hasPrefix removePrefix removeSuffix stringToCharacters;
  inherit (final.lib.strings) escapeC normalizePath;
in {
  escapeSystemdString = s: let
    replacePrefix = p: r: s: (if (hasPrefix p s) then r + (removePrefix p s) else s);
  in
    replaceStrings ["/"] ["-"]
    (replacePrefix "." (escapeC ["."] ".")
    (escapeC (stringToCharacters " !\"#$%&'()*+,;<=>=@[\\]^`{|}~-")
    s));

  escapeSystemdPath = s: let
    replacePrefix = p: r: s: (if (hasPrefix p s) then r + (removePrefix p s) else s);
    trim = s: removeSuffix "/" (removePrefix "/" s);
    normalizedPath = normalizePath s;
  in
    replaceStrings ["/"] ["-"]
    (replacePrefix "." (escapeC ["."] ".")
    (escapeC (stringToCharacters " !\"#$%&'()*+,;<=>=@[\\]^`{|}~-")
    (if normalizedPath == "/" then normalizedPath else trim normalizedPath)));
}
