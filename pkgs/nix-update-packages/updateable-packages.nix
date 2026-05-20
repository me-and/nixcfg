let
  lib = import <nixpkgs/lib>;
in
lib.flip lib.pipe [
  (lib.filterAttrs (n: v: v.passthru.updateScript or null != null))
  builtins.attrNames
]
