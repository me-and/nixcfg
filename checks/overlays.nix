# Check any packages I'm changing in an overlay (a) compile and (b) have any
# tests they define also compile.
{
  lib,
  pkgs,
  mylib,
  overlays,
}:
let
  inherit (builtins)
    attrNames
    elem
    getAttr
    map
    ;
  inherit (lib.attrsets) optionalAttrs recurseIntoAttrs;
  inherit (lib.fixedPoints) composeManyExtensions extends fix;
  inherit (lib.trivial) warnIfNot;
  inherit (mylib) removeAll unionOfDisjointAttrsList;

  # Work out the set of attribute names that exist when applying all the
  # overlays to an empty set.  This is the list of attributes in nixpkgs that
  # are added or changed by the overlays, and thankfully Nix's lazy evaluation
  # means we can generate that list without any of them needing to actually
  # evaluate.
  #
  # The only alternative I could think of was computing the full Nixpkgs
  # fixedpoint both with and without the overlays and comparing the results,
  # but that would (a) require *a lot* of computing, since comparing results
  # would require working out all the derivations, and (b) handling the many
  # derivations that don't successfully evaluate at all.
  start = final: { };
  extensions = composeManyExtensions overlays;
  fixedpoint = fix (extends extensions start);
  # Need to remove sops-ssh-to-age per
  # https://github.com/Mic92/sops-nix/pull/861
  newOrChanged =
    let
      packageNames = attrNames fixedpoint;
    in
    warnIfNot (elem "sops-ssh-to-age" packageNames) ''
      No longer need special handling of sops-ssh-to-age.
    '' removeAll [ "mypkgs" "sops-ssh-to-age" ] packageNames;
in
recurseIntoAttrs (
  unionOfDisjointAttrsList (
    map (
      p:
      let
        pkg = getAttr p pkgs;
      in
      {
        "${p}" = recurseIntoAttrs {
          package = pkg;
          tests = recurseIntoAttrs (pkg.passthru.tests or { });
        };
      }
    ) newOrChanged
  )
)
