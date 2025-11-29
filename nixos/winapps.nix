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
{ pkgs, ... }:
{
  virtualisation.podman.enable = true;
  environment.systemPackages =
    (with pkgs; [
      podman
      podman-compose
    ])
    ++ (with pkgs.mypkgs.winapps; [
      winapps
      winapps-launcher
      winapps-rdp
    ]);
}
