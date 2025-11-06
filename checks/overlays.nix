# Check any packages I'm changing in an overlay (a) compile and (b) have any
# tests they define also compile.
#
# TODO: find a way to automatically keep this in sync with overlays I create,
# rather than needing the list of packages to be maintained separately.
{
  lib,
  pkgs,
  mylib,
}:
let
  packageNames = [
    "btdu"
    "nix-heuristic-gc"
    "openvpn"
    "rclone"
    "taskserver"
    "taskwarrior2"
    "wslu"
  ];
in
lib.recurseIntoAttrs (
  mylib.unionOfDisjointAttrsList (
    builtins.map (
      p:
      let
        pkg = builtins.getAttr p pkgs;
      in
      {
        "${p}" = lib.recurseIntoAttrs (
          {
            package = pkg;
          }
          // lib.optionalAttrs (pkg ? passthru.tests) { tests = lib.recurseIntoAttrs pkg.passthru.tests; }
        );
      }
    ) packageNames
  )
)
