{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (config.lib.file) mkOutOfStoreSymlink;

  python = pkgs.python3.withPackages (pp: [
    # dateutil needed for asmodeus
    pp.dateutil
  ]);

  myPkgs = import ./mypackages.nix {inherit pkgs;};

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
    hash = "sha256-a6dHg0QwTkgfVNKeVBYw0L1mYKVna60/sHptD7+e4gI=";
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
        netrcPhase = ''
          if [ -z "$NIX_GITHUB_PRIVATE_USERNAME" -o -z "$NIX_GITHUB_PRIVATE_PASSWORD" ]; then
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
        netrcImpureEnvVars = [
          "NIX_GITHUB_PRIVATE_USERNAME"
          "NIX_GITHUB_PRIVATE_PASSWORD"
        ];
      });

  isWsl =
    (builtins.pathExists /proc/sys/fs/binfmt_misc/WSLInterop)
    || (builtins.pathExists /proc/sys/fs/binfmt_misc/WSLInterop-late);
  windowsHomeDir = builtins.readFile (
    # TODO Can I convert this to use ${pkgs.wslu}/bin/wslvar
    pkgs.runCommandLocal "homedir" {__noChroot = true;}
    ''
      /bin/wslpath "$(/mnt/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe -c '$env:UserProfile')" |
          ${pkgs.coreutils}/bin/tr -d '\r\n' >$out
    ''
  );

  nix-locate-bin = pkgs.writeShellApplication {
    name = "nix-locate-bin";
    text = ''
      ${pkgs.nix-index}/bin/nix-locate \
          --minimal \
          --no-group \
          --type x --type s \
          --top-level \
          --whole-name \
          --at-root \
          "/bin/$1"
    '';
  };
in {
  imports =
    [
      ./local-config.nix
      ./homeshick.nix
    ]
    ++ (
      lib.optional (builtins.pathExists ~/.config/home-manager-work)
      ~/.config/home-manager-work
    );

  home = {
    username = "adam";
    homeDirectory = "/home/adam";

    packages = with pkgs; [
      alejandra
      ascii
      dos2unix
      fzf
      gh
      htop
      jq
      lesspipe
      moreutils
      mosh
      nix-diff
      nix-locate-bin
      psmisc
      pv
      python
      silver-searcher
      taskwarrior

      # Use the Git version possibly configured in local-config.nix.  This is
      # handled here rather than with config.programs.git.enable because that
      # would also result in Home Manager trying to manage my Git config, which
      # I'm not (yet) ready for.
      config.programs.git.package

      # My packages.
      myPkgs.nix-about
      myPkgs.toil
    ];

    sessionVariables = {
      # Ideally this wouldn't be handled here but instead by Nix dependency
      # management -- nothing should rely on the general site environment being
      # set up correctly -- but this is the quick solution while there are
      # plenty of things I care about that aren't yet integrated into Home
      # Manager.
      PYTHONPATH = "${python}/${python.sitePackages}";
    };

    file = let
      winHomeLink = lib.optionalAttrs isWsl {
        WinHome = {source = mkOutOfStoreSymlink windowsHomeDir;};
      };

      # This isn't very idiomatic for Nix, but it's a quick and easy solution
      # for moving my existing config into Nix.
      systemdLinkTree = lib.optionalAttrs config.systemd.user.enable {
        ".config/systemd" = {
          recursive = true;
          source = "${systemdHomeshick}/systemd";
        };
        ".local" = {
          recursive = true;
          source = "${systemdHomeshick}/home/.local";
        };
      };
    in
      winHomeLink // systemdLinkTree;

    # Get Bash to check for local mail.
    sessionVariables.MAILPATH = "/var/spool/mail/${config.home.username}";
  };

  homeshick = let
    doLink = url: {inherit url;};
    dontLink = url: {
      inherit url;
      link = false;
    };
  in {
    enable = true;
    repos = [
      (doLink "https://github.com/me-and/castle")
      (dontLink "https://github.com/mileszs/ack.vim")
      (dontLink "https://github.com/me-and/asmodeus")
      (dontLink "https://github.com/magicmonty/bash-git-prompt")
      (dontLink "https://github.com/vito-c/jq.vim")
      (dontLink "https://github.com/aklt/plantuml-syntax")
      (dontLink "https://github.com/luochen1990/rainbow")
      (dontLink "https://github.com/sirtaj/vim-openscad")
      (dontLink "https://github.com/junegunn/vim-plug")
      (dontLink "https://github.com/lervag/vimtex")
    ];
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
