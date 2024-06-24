{pkgs ? import <nixpkgs> {}}: let
  inherit (pkgs) callPackage;
in {
  gitMaster = callPackage ./package.nix {ref = "master";};
  gitNext = callPackage ./package.nix {ref = "next";};
}
