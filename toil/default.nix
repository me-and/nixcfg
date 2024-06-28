{pkgs ? import <nixpkgs> {}}: {
  toil = pkgs.callPackage ./package.nix {};
}
