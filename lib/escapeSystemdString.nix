{ lib }:
s:
let
  inherit (lib.strings)
    escapeC
    hasPrefix
    removePrefix
    replaceStrings
    stringToCharacters
    ;

  replacePrefix =
    p: r: s:
    (if (hasPrefix p s) then r + (removePrefix p s) else s);
in
replaceStrings [ "/" ] [ "-" ] (
  replacePrefix "." (escapeC [ "." ] ".") (
    escapeC (stringToCharacters " !\"#$%&'()*+,;<=>=@[\\]^`{|}~-") s
  )
)
