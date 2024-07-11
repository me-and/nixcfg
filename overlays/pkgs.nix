final: prev: let
  # Need to compute the package names without referring to final or prev, as
  # otherwise Nix can't tell what is defined in the overlay before it has
  # computed the overlay, and we get an infinite recursion.  Thankfully, the
  # package names *really* shouldn't change from using the system <nixpkgs>
  # as ../pkgs defaults to using, rather than the ones being computed as part
  # of the overlay.
  #
  # See also
  # https://discourse.nixos.org/t/infinite-recursion-getting-started-with-overlays/48880/5
  packageNames = builtins.attrNames (import ../pkgs {});
  packages = final.callPackages ../pkgs {};
in
  # Compute the set of packages using the attribute names computed without
  # using final or prev, and the actual packages as computed using the overlaid
  # callPackage.
  builtins.listToAttrs (
    builtins.map (
      name: {
        inherit name;
        value = builtins.getAttr name packages;
      }
    )
    packageNames
  )
