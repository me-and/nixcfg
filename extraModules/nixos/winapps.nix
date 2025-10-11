# TODO Write a helper script to hold the user's hand through the following steps:
#
# - Initial install of the Windows VM per
#   https://github.com/winapps-org/winapps/blob/main/docs/docker.md (which
#   should just be running `podman-compose --file
#   ${winapps.winapps}/src/compose.yaml up`).
# - Actually setting Windows up, which requires setting up a username and
#   password and installing any applications they're after.
# - Adding compose.yaml, with modifications per
#   https://github.com/winapps-org/winapps/blob/main/docs/docker.md, to
#   ~/.config/winapps.
# - Adding winapps.conf per
#   https://github.com/winapps-org/winapps/blob/main/README.md to
#   ~/.config/winapps.
# - Running the winapps installer to set up links to the Windows applications.
{
  config,
  pkgs,
  flake,
  ...
}: let
  system = config.nixpkgs.hostPlatform.system;
  winappsPkgs = flake.winapps.packages."${system}";
in {
  virtualisation.podman.enable = true;
  environment.systemPackages = [
    pkgs.podman-compose
    winappsPkgs.winapps
    winappsPkgs.winapps-launcher
  ];

  nix.settings = {
    substituters = ["https://winapps.cachix.org/"];
    trusted-public-keys = ["winapps.cachix.org-1:HI82jWrXZsQRar/PChgIx1unmuEsiQMQq+zt05CD36g="];
  };
}
