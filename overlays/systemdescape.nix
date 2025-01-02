# Based on nixos/lib/utils.nix
final: prev: let
  inherit (final.lib) hasPrefix removePrefix removeSuffix replaceStrings stringToCharacters;
  inherit (final.lib.strings) escapeC normalizePath;
in {
  escapeSystemdString = s: let
    replacePrefix = p: r: s: (
      if (hasPrefix p s)
      then r + (removePrefix p s)
      else s
    );
  in
    replaceStrings ["/"] ["-"] (
      replacePrefix "." (escapeC ["."] ".") (
        escapeC (stringToCharacters " !\"#$%&'()*+,;<=>=@[\\]^`{|}~-") s
      )
    );

  escapeSystemdPath = s: let
    trim = s: removeSuffix "/" (removePrefix "/" s);
    normalizedPath = normalizePath s;
  in
    final.escapeSystemdString (
      if normalizedPath == "/"
      then normalizedPath
      else trim normalizedPath
    );
}
