# Want the fix at https://github.com/rclone/rclone/commit/e053c8a1c03e9c4396e3588bbfc432ed4ff79814
final: prev: let
  rcloneBase = final.lib.channels.mostStablePackageVersionAtLeast {
    name = "rclone";
    version = "1.67";
    testFirst = [prev.rclone];
    excludeOverlays = ["rclone"];
  };
in {
  rclone = rcloneBase.overrideAttrs (prevAttrs: {
    patches = (prevAttrs.patches or []) ++ [./skip-specials.diff];
  });
}
