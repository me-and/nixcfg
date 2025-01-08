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
  lib,
  pkgs,
  ...
}: let
  cfg = config.programs.winapps;

  winapps = (import <winapps>).packages."${config.nixpkgs.system}";
in {
  options.programs.winapps = {
    enable = lib.mkEnableOption "winapps";
    backend = lib.mkOption {
      description = ''
        Backend to use for Winapps.

        Currently only podman is supported; using any other backend will
        require you to set it up yourself.
      '';
      type = lib.types.enum ["podman"];
      default = "podman";
    };
  };

  config = lib.mkIf cfg.enable {
    nix.channels.winapps = "https://github.com/winapps-org/winapps/archive/main.tar.gz";

    virtualisation.podman.enable = true;
    environment.systemPackages = [
      pkgs.podman-compose
      winapps.winapps
      winapps.winapps-launcher
    ];

    nix.settings = {
      substituters = ["https://winapps.cachix.org/"];
      trusted-public-keys = ["winapps.cachix.org-1:HI82jWrXZsQRar/PChgIx1unmuEsiQMQq+zt05CD36g="];
    };
  };
}
