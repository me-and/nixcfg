{ pkgs }:
let
  inherit (pkgs) callPackage;
in {
  gitMaster = callPackage ./git/package.nix { ref = "master"; };
  gitNext = callPackage ./git/package.nix { ref = "next"; };

  nix-about = callPackage ./nix-about/package.nix { };
}
