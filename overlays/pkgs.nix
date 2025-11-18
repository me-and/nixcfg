{ inputs }:
final: prev: {
  mylib = import ../lib { inherit (final) lib; };
  mypkgs = final.lib.recurseIntoAttrs (
    removeAttrs (import ../pkgs {
      inherit inputs;
      inherit (final) lib pkgs mylib;
    }) [ "everything" ]
  );
}
