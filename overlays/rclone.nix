final: prev: let
  # Want the fix at https://github.com/rclone/rclone/commit/e053c8a1c03e9c4396e3588bbfc432ed4ff79814
  rcloneBase = let
    rcloneBase = final.lib.channels.mostStablePackageVersionAtLeast {
      name = "rclone";
      version = "1.67";
      testFirst = [prev.rclone];
      excludeOverlays = ["rclone.nix"];
    };
  in
    final.lib.warnIf
    (rcloneBase == prev.rclone)
    "unnecessary version check in rclone.nix overlay"
    rcloneBase;

  # https://github.com/rclone/rclone/pull/8151
  patch = final.fetchGitHubPatch {
    owner = "rclone";
    repo = "rclone";
    commit = "f4f0a296077247dfb8dc301c2c49105491efc34b";
    hash = "sha256-CV2JGzDzOui28pPhzZUFslj+VPpsTTo/GMsBQRFtA0U=";
  };
in {
  rclone = rcloneBase.overrideAttrs (prevAttrs: {
    patches = (prevAttrs.patches or []) ++ [patch];
  });
}
