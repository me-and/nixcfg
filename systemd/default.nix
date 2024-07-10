{
  config,
  lib,
  pkgs,
  ...
}: let
  myPkgs = pkgs.callPackage ../mypackages.nix {};

  writeShellScript = pkgs.callPackage ../writeshellscript.nix {};

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
    hash = "sha256-F6HurEz6nzNToKeuZGbvz9YXvvV15ykdKqrRLkosBnU=";
  in
    pkgs.fetchzip ({
        inherit name hash;
        url =
          "https://api.github.com/repos/${owner}/${repo}/tarball"
          + lib.optionalString (rev != "HEAD") "/${rev}";
        extension = "tar.gz";
        passthru = {gitRepoUrl = "https://github.com/${owner}/${repo}.git";};
      }
      // lib.optionalAttrs private {
        netrcPhase = writeShellScript {
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
in {
  # This isn't very idiomatic for Nix, but it's a quick and easy solution for
  # moving my existing config into Nix.
  home.file = lib.mkIf config.systemd.user.enable {
    ".config/systemd" = {
      recursive = true;
      source = "${systemdHomeshick}/systemd";
    };
    ".local" = {
      recursive = true;
      source = "${systemdHomeshick}/home/.local";
    };
  };

  systemd.user.services."mail-state@" = {
    Unit.Description = "Unit %i state report";
    Service.Type = "oneshot";
    Service.ExecStart = let
      reportScript = writeShellScript {
        name = "mailstate.sh";
        bashOptions = ["errexit" "nounset"];
        text = ''
          unit="$1"
          user="$2"
          shorthost="$3"
          longhost="$4"

          unit_state="$(systemctl --user show -PActiveState "$unit")"

          SYSTEMD_COLORS=True SYSTEMD_URLIFY=False \
              systemctl --user status "$unit" |
              ${myPkgs.colourmail}/bin/colourmail \
                  -s "Unit $unit $unit_state on $shorthost" \
                  -r "$user on $shorthost <''${user}@''${longhost}>" \
                  -- "$user"
        '';
      };
    in "${reportScript} %i %u %l %H";
  };
}
