final: prev: {
  mylib = import ../lib.nix { lib = final.lib; };
  mypkgs = import ../. { inherit (final) lib pkgs mylib; };
}
