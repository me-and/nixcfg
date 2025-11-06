final: prev: {
  mylib = import ../lib { lib = final.lib; };
  mypkgs = import ../. { inherit (final) lib pkgs mylib; };
}
