{ config, lib, pkgs, ... }:

let
  python = pkgs.python3.withPackages (pp: [
    # dateutil needed for asmodeus
    pp.dateutil
  ]);

  myPkgs = import ./mypackages.nix { inherit pkgs; };

  # This used to be a Homeshick castle, and can still be used as one, but it's
  # used here as a starting point for bringing my systemd config into Home
  # Manager.
  #
  # Would use pkgs.fetchFromGitHub but for
  # <https://github.com/NixOS/nixpkgs/issues/321481>, so the below is an
  # unwrapped version of fetchFromGitHub with my patch applied.  The arguments
  # in the `let` block are the ones I'd otherwise pass to fetchFromGitHub.
  systemdHomeshick =
  let
    owner = "me-and";
    repo = "user-systemd-config";
    name = repo;
    rev = "HEAD";
    private = true;
    hash = "sha256-AwnRP8VGjm+cEq+y7Pqi8XXh8QdXHRdjvNMAjV2CeZ4=";
  in pkgs.fetchzip ({
    inherit name hash;
    url = "https://api.github.com/repos/${owner}/${repo}/tarball" + lib.optionalString (rev != "HEAD") "/${rev}";
    extension = "tar.gz";
    passthru = { gitRepoUrl = "https://github.com/${owner}/${repo}.git"; };
  } // lib.optionalAttrs private {
    netrcPhase = ''
      if [ -z "$NIX_GITHUB_PRIVATE_USERNAME" -o -z "$NIX_GITHUB_PRIVATE_PASSWORD" ]; then
        echo 'Error: cannot get systemdHomeshick without the nix building process (nix-daemon in multi user mode) having the NIX_GITHUB_PRIVATE_USERNAME and NIX_GITHUB_PRIVATE_PASSWORD env vars set.' >&2
        exit 1
      fi
      cat >netrc <<EOF
      machine api.github.com
              login $NIX_GITHUB_PRIVATE_USERNAME
              password $NIX_GITHUB_PRIVATE_PASSWORD
      EOF
    '';
    netrcImpureEnvVars = [ "NIX_GITHUB_PRIVATE_USERNAME" "NIX_GITHUB_PRIVATE_PASSWORD" ];
  });
in {
  imports = [
    ./local-config.nix
    ./homeshick.nix
  ]
  ++ lib.optional (builtins.pathExists ~/.config/home-manager-work) ~/.config/home-manager-work;

  home = {
    username = "adam";
    homeDirectory = "/home/adam";

    packages = with pkgs; [
      ascii
      fzf
      gh
      htop
      jq
      lesspipe
      moreutils
      mosh
      nix-diff
      psmisc
      python
      silver-searcher
      taskwarrior

      # Use the Git version possibly configured in local-config.nix.  This is
      # handled here rather than with config.programs.git.enable because that
      # would also result in Home Manager trying to manage my Git config, which
      # I'm not (yet) ready for.
      config.programs.git.package

      # Use nix-about.
      myPkgs.nix-about
    ];

    sessionVariables = {
      # Ideally this wouldn't be handled here but instead by Nix dependency
      # management -- nothing should rely on the general site environment being
      # set up correctly -- but this is the quick solution while there are
      # plenty of things I care about that aren't yet integrated into Home
      # Manager.
      PYTHONPATH = "${python}/${python.sitePackages}";
    };

    # This isn't very idiomatic for Nix, but it's a quick and easy solution for
    # moving my existing config into Nix.
    file = lib.mkIf config.systemd.user.enable {
      ".config/systemd" = {
        recursive = true;
        source = "${systemdHomeshick}/systemd";
      };
      ".local" = {
        recursive = true;
        source = "${systemdHomeshick}/home/.local";
      };
    };
  };

  homeshick = {
    enable = true;
    repos = [
      { url = "https://github.com/me-and/castle"; }
      { url = "https://github.com/mileszs/ack.vim"; link = false; }
      { url = "https://github.com/me-and/asmodeus"; link = false; }
      { url = "https://github.com/magicmonty/bash-git-prompt"; link = false; }
      { url = "https://github.com/vito-c/jq.vim"; link = false; }
      { url = "https://github.com/aklt/plantuml-syntax"; link = false; }
      { url = "https://github.com/luochen1990/rainbow"; link = false; }
      { url = "https://github.com/sirtaj/vim-openscad"; link = false; }
      { url = "https://github.com/junegunn/vim-plug"; link = false; }
      { url = "https://github.com/lervag/vimtex"; link = false; }
    ];
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
