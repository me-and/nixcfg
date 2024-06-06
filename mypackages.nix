{ pkgs ? import <nixpkgs> {} }:
let
  inherit (pkgs) callPackage;
in {
  inherit (import ./git { inherit pkgs; }) gitMaster gitNext;

  inherit (import ./nix-about { inherit pkgs; }) nix-about;
}
