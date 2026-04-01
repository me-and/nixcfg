# https://github.com/NixOS/nixpkgs/pull/505796
final: prev:
let
  inherit (final) callPackage lib;
in
{
  gh-gonest =
    if prev ? gh-gonest then
      lib.warn "unnecessary gh-gonest overlay" prev.gh-gonest
    else
      callPackage ./package.nix { };
}
