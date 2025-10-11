final: prev: {
  mylib = import ../lib.nix {lib = final.lib;};
  mypkgs = import ../. {pkgs = final;};
}
