{pkgs ? import <nixpkgs> {}}: let
  inherit (pkgs) callPackage;
in {
  colourmail = callPackage ./colourmail {};

  gitMaster = callPackage ./git {ref = "master";};
  gitNext = callPackage ./git {ref = "next";};

  mtimewait = callPackage ./mtimewait {};

  nix-about = callPackage ./nix-about {};

  toil = callPackage ./toil {};
}
