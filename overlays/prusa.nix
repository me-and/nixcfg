# https://github.com/NixOS/nixpkgs/pull/374850
final: prev: let
  prusa-slicer-base = final.lib.channels.mostStablePackageVersionAtLeast {
    name = "prusa-slicer";
    version = "2.9.0";
    excludeOverlays = ["prusa"];
    testFirst = [prev.prusa-slicer];
  };
  patch = final.fetchpatch {
    url = "https://github.com/prusa3d/PrusaSlicer/commit/cdc3db58f9002778a0ca74517865527f50ade4c3.patch";
    hash = "sha256-zgpGg1jtdnCBaWjR6oUcHo5sGuZx5oEzpux3dpRdMAM=";
  };
in {
  prusa-slicer = prusa-slicer-base.overrideAttrs (prevAttrs: {
    patches = (prevAttrs.patches or []) ++ [patch];
  });
}
