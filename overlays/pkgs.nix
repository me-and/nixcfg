# TODO Maybe I shouldn't be relying on an overlay here.  If I want someone else
# to be able to use one of my modules, including ones that rely on my packages,
# they shouldn't need to also apply my overlays; that should be a separate
# option.
{ inputs }:
final: prev: {
  mylib = import ../lib { inherit (final) lib; };
  mypkgs = final.lib.recurseIntoAttrs (
    import ../pkgs {
      inherit inputs;
      inherit (final) lib pkgs mylib;
    }
  );
}
