final: prev:
let
  # Want the fix at https://github.com/rclone/rclone/commit/e053c8a1c03e9c4396e3588bbfc432ed4ff79814
  # https://github.com/rclone/rclone/pull/8151
  patch = final.mypkgs.fetchGitHubPatch {
    owner = "rclone";
    repo = "rclone";
    commit = "f4f0a296077247dfb8dc301c2c49105491efc34b";
    hash = "sha256-CV2JGzDzOui28pPhzZUFslj+VPpsTTo/GMsBQRFtA0U=";
  };
in
{
  rclone = prev.rclone.overrideAttrs (prevAttrs: {
    patches = (prevAttrs.patches or [ ]) ++ [ patch ];
  });
}
