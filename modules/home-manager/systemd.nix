{
  config,
  lib,
  pkgs,
  ...
}: let
  # This used to be a Homeshick castle, and can still be used as one, but it's
  # used here as a starting point for bringing my systemd config into Home
  # Manager.
  #
  # Would use pkgs.fetchFromGitHub but for
  # <https://github.com/NixOS/nixpkgs/issues/321481>, so the below is an
  # unwrapped version of fetchFromGitHub with my patch applied.  The arguments
  # in the `let` block are the ones I'd otherwise pass to fetchFromGitHub.
  systemdHomeshick = pkgs.fetchFromGitHub rec {
    owner = "me-and";
    repo = "user-systemd-config";
    name = repo;
    rev = "HEAD";
    private = true;
    hash = "sha256-F6HurEz6nzNToKeuZGbvz9YXvvV15ykdKqrRLkosBnU=";
  };
in
  lib.mkMerge [
    {
      # Not sure why this needs to be unconditional, but I get a recursion
      # error if it isn't.
      nixpkgs.overlays = map import [
        ../../overlays/checkedshellscript.nix
        ../../overlays/fetchgithub.nix
      ];

      # The systemd configuration will look after not evaluating this if
      # systemd isn't enabled.
      systemd.user.services."mail-state@" = {
        Unit.Description = "Unit %i state report";
        Service.Type = "oneshot";
        Service.ExecStart = let
          reportScript = pkgs.writeCheckedShellScript {
            name = "mailstate.sh";
            bashOptions = ["errexit" "nounset"];
            text = ''
              unit="$1"
              user="$2"
              shorthost="$3"
              longhost="$4"

              unit_state="$(systemctl --user show -PActiveState "$unit")"

              # shellcheck disable=SC2312 # systemctl expected to return non-zero
              SYSTEMD_COLORS=True SYSTEMD_URLIFY=False \
                  systemctl --user status "$unit" |
                  ${pkgs.colourmail}/bin/colourmail \
                      -s "Unit $unit $unit_state on $shorthost" \
                      -r "$user on $shorthost <''${user}@''${longhost}>" \
                      -- "$user"
            '';
          };
        in "${reportScript} %i %u %l %H";
      };
    }

    (lib.mkIf config.systemd.user.enable {
      # This isn't very idiomatic for Nix, but it's a quick and easy solution for
      # moving my existing config into Nix.
      home.file = {
        ".config/systemd" = {
          recursive = true;
          source = "${systemdHomeshick}/systemd";
        };
        ".local" = {
          recursive = true;
          source = "${systemdHomeshick}/home/.local";
        };
      };
    })
  ]
