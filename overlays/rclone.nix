final: prev: let
  # https://github.com/rclone/rclone/pull/8151
  patch = final.fetchGitHubPatch {
    owner = "rclone";
    repo = "rclone";
    commit = "f4f0a296077247dfb8dc301c2c49105491efc34b";
    hash = "sha256-CV2JGzDzOui28pPhzZUFslj+VPpsTTo/GMsBQRFtA0U=";
  };
in {
  rclone = prev.rclone.overrideAttrs (prevAttrs: {
    patches = (prevAttrs.patches or []) ++ [patch];
  });
}
