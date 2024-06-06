{ pkgs ? import <nixpkgs> {} }: {
nix-about = pkgs.callPackage ./package.nix { };
}
