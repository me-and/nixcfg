{ inputs }:
final: prev: {
  mylib = import ../lib { inherit (final) lib; };
  mypkgs = import ../pkgs { inherit inputs; inherit (final) lib pkgs mylib; };
}
