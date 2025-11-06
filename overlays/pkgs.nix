final: prev: {
  mylib = import ../lib { lib = final.lib; };
  mypkgs = import ../pkgs { inherit (final) lib pkgs mylib; };
}
