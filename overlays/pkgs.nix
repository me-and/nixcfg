{ inputs }:
final: prev: {
  mylib = import ../lib { inherit (final) lib; };
  mypkgs = removeAttrs (import ../pkgs {
    inherit inputs;
    inherit (final) lib pkgs mylib;
  }) [ "everything" ];
}
