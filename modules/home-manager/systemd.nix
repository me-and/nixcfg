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
  systemdHomeshick = let
    owner = "me-and";
    repo = "user-systemd-config";
    name = repo;
    rev = "HEAD";
    private = true;
    hash = "sha256-/4iWFqv2IQsQ29jUpZXZ8kg3qthceZdI2c34EmF2PZY=";
  in
    lib.warnIf (lib.oldestSupportedReleaseIsAtLeast 2505)
    ''
      Unnecessary working around GitHub API and fetchFromGitHub limitations in
      ${./.}/systemd.nix
    ''
    pkgs.fetchzip ({
        inherit name hash;
        url =
          "https://api.github.com/repos/${owner}/${repo}/tarball"
          + lib.optionalString (rev != "HEAD") "/${rev}";
        extension = "tar.gz";
        passthru = {gitRepoUrl = "https://github.com/${owner}/${repo}.git";};
      }
      // lib.optionalAttrs private {
        netrcPhase = pkgs.writeCheckedShellScript {
          name = "fetch-systemd-homeshick.sh";
          text = ''
            if [[ -z "$NIX_GITHUB_PRIVATE_USERNAME" || -z "$NIX_GITHUB_PRIVATE_PASSWORD" ]]; then
              cat <<EOF >&2
            Error: cannot get systemdHomeshick without the nix building process
            (nix-daemon in multi-user mode) having the
            NIX_GITHUB_PRIVATE_USERNAME and NIX_GITHUB_PRIVATE_PASSWORD
            environment variables set.
            EOF
              exit 1
            fi
            cat >netrc <<EOF
            machine api.github.com
                    login $NIX_GITHUB_PRIVATE_USERNAME
                    password $NIX_GITHUB_PRIVATE_PASSWORD
            EOF
          '';
        };
        netrcImpureEnvVars = [
          "NIX_GITHUB_PRIVATE_USERNAME"
          "NIX_GITHUB_PRIVATE_PASSWORD"
        ];
      });
in
  lib.mkMerge [
    {
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
