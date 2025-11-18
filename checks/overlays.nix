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
    mapAttrs
    typeOf
    ;
  inherit (lib.attrsets) optionalAttrs recurseIntoAttrs;
  inherit (lib.fixedPoints) composeManyExtensions extends fix;
  inherit (lib.lists) remove;
  inherit (lib.trivial) warnIfNot;
  inherit (mylib) unionOfDisjointAttrsList;

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
    '' remove "sops-ssh-to-age" packageNames;

  # Vaguely based on flake-utils.lib.flattenTree, but aiming to extract
  # explicitly derivations and any passthru.tests.<name> derivations.
  #
  # TODO This seems to drop the set of packages in mypkgs, where I'd hoped and
  # expected it would extend the tests to include both building those packages
  # and building any tests those packages define.
  recurseForPackages =
    v:
    if typeOf v != "set" then
      { }
    else if v.type or "" == "derivation" then
      {
        package = v;
        tests = recurseIntoAttrs (v.passthru.tests or { });
      }
    else if v.recurseForDerivations or false then
      mapAttrs (n: s: recurseForPackages s) v
    else
      { };
in
recurseIntoAttrs (
  unionOfDisjointAttrsList (
    map (
      p:
      let
        v = getAttr p pkgs;
      in
      {
        "${p}" = recurseIntoAttrs (recurseForPackages v);
      }
    ) newOrChanged
  )
)
