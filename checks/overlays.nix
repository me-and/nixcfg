# Check any packages I'm changing in an overlay (a) compile and (b) have any
# tests they define also compile.
{
  lib,
  pkgs,
  mylib,
  overlays,
}:
let
  inherit (builtins) attrNames getAttr;
  inherit (lib.attrsets) optionalAttrs recurseIntoAttrs;
  inherit (lib.fixedPoints) composeManyExtensions extends fix;
  inherit (lib.meta) availableOn;
  inherit (mylib) removeAll unionOfDisjointAttrsList;
  inherit (pkgs.stdenv) hostPlatform;

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
  #
  # kdePackages gets special attention because it's a package set that doesn't
  # have any handy overlay function built in (unlike Python).  There may be
  # others like it, but I've not yet needed to deal with them...
  #
  # TODO Add tests for Python overlays.
  start = final: { kdePackages = { }; };
  extensions = composeManyExtensions overlays;
  fixedpoint = fix (extends extensions start);
  newOrChanged =
    let
      packageNames = attrNames fixedpoint;
    in
    removeAll [ "kdePackages" "mypkgs" ] packageNames;

  baseChecks = recurseIntoAttrs (
    unionOfDisjointAttrsList (
      map (
        p:
        let
          pkg = getAttr p pkgs;
        in
        optionalAttrs (availableOn hostPlatform pkg) {
          "${p}" = recurseIntoAttrs {
            package = pkg;
            tests = recurseIntoAttrs (pkg.passthru.tests or { });
          };
        }
      ) newOrChanged
    )
  );

  # TODO Remove the repetition between these definitions and the base cases.
  kdeNewOrChanged = attrNames (fixedpoint.kdePackages or { });
  kdeChecks = recurseIntoAttrs (
    unionOfDisjointAttrsList (
      map (
        p:
        let
          pkg = getAttr p pkgs.kdePackages;
        in
        optionalAttrs (availableOn hostPlatform pkg) {
          "${p}" = recurseIntoAttrs {
            package = pkg;
            tests = recurseIntoAttrs (pkg.passthru.tests or { });
          };
        }
      ) kdeNewOrChanged
    )
  );
in
baseChecks // { kdePackages = kdeChecks; }
