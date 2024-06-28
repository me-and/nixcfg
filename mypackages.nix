{pkgs ? import <nixpkgs> {}}: {
  inherit (import ./git {inherit pkgs;}) gitMaster gitNext;

  inherit (import ./nix-about {inherit pkgs;}) nix-about;

  inherit (import ./toil {inherit pkgs;}) toil;
}
