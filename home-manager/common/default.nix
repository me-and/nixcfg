{
  config,
  lib,
  pkgs,
  ...
}: let
  python = pkgs.python3.withPackages (pp: [
    # dateutil needed for asmodeus
    pp.dateutil
    # requests needed for petition signing script
    pp.requests
  ]);
in {
  imports = [
    ../../common
    ./bash
    ./firefox.nix
    ./homeshick.nix
    ./keepassxc.nix
    ./taskwarrior.nix
    ../../modules/home-manager
    ../../modules/shared
  ];

  home = {
    homeDirectory = lib.mkDefault "/home/${config.home.username}";

    # We *don't* add home-manager here, nor use home-manager.enable, because we
    # want to use the system home-manager installation.  In particular, that
    # avoids inconsistent Home Manager and NixOS installation versions when
    # there's a new NixOS release.
    packages = with pkgs; [
      aaisp-quota
      alejandra
      ascii
      bintools
      coldiff
      dig.dnsutils
      dos2unix
      file-age
      final-eol
      fzf
      gh
      git-filter-repo
      git-report
      gnumake
      htop
      jq
      lesspipe
      lsof
      man-pages
      moreutils
      mosh
      mtimewait
      ncdu
      nix-about
      nix-dangling-roots
      nix-diff
      nix-locate-bin
      nix-output-monitor
      nixos-generators
      nixpkgs-review
      psmisc
      pv
      python
      shellcheck
      silver-searcher
      tmux
      tmux-taskloop
      tmux-xpanes
      toil
      unzip

      # Use the Git version possibly configured elsewhere.  This is handled
      # here rather than with config.programs.git.enable because that would
      # also result in Home Manager trying to manage my Git config, which I'm
      # not (yet) ready for.
      config.programs.git.package
    ];

    sessionVariables = {
      # Ideally this wouldn't be handled here but instead by Nix dependency
      # management -- nothing should rely on the general site environment being
      # set up correctly -- but this is the quick solution while there are
      # plenty of things I care about that aren't yet integrated into Home
      # Manager.
      #
      # TODO Move to using sessionSearchVariables once
      # https://github.com/nix-community/home-manager/commit/277eea1cc7a5c37ea0b9aa8198cd1f2db3d6715c
      # exists
      PYTHONPATH = "$HOME/.local/lib/python3/my-packages:${python}/${python.sitePackages}\${PYTHONPATH:+:$PYTHONPATH}";

      # TODO Move to using sessionPath once sessionSearchVariables is available
      # and therefore paths are prepended rather than appended.
      # TODO Surely adding .nix-profile/bin ought to be handled somewhere else
      # and not need explicit configuration!?
      PATH = "$HOME/.local/bin:$HOME/.nix-profile/bin\${PATH:+:$PATH}";

      EDITOR = "vim";
      VISUAL = "vim";

      LANG = "en_GB.UTF-8";
      LANGUAGE = "en_GB:en";
      TIME_STYLE = "+%a %_d %b  %Y\n%a %_d %b %R";

      # Don't use -S automatically when calling `less` from systemctl commands; I
      # find it annoying more often than I find it helpful.
      SYSTEMD_LESS = "FRXMK";

      # Get Bash to check for local mail.
      MAILPATH = "/var/spool/mail/${config.home.username}";
    };
  };

  programs.mypy.config.mypy.cache_dir = "${config.xdg.cacheHome}/mypy";

  # Don't expect this to ever clean much up, but it's a backstop against
  # ancient versions hanging around unnecessarily.
  #
  # TODO Remove testing printf
  systemd.user.services.nix-remove-old-profiles = {
    Unit.Description = "Delete old Nix profiles";
    Service = {
      Type = "oneshot";
      ExecStart = pkgs.writeCheckedShellScript {
        name = "rm-nix-profiles";
        text = let
          nixPackage =
            if config.nix.package == null
            then pkgs.nix
            else config.nix.package;
        in ''
          for p in ${lib.escapeShellArg config.xdg.stateHome}/nix/profiles/*; do
              if [[ "$p" =~ (.*)-[0-9]+-link ]] &&
                  [[ -e "''${BASH_REMATCH[1]}" ]]
              then
                  # This is a version of a profile, so ignore it
                  :
              else
                  ${nixPackage}/bin/nix-env --delete-generations 180d -p "$p"
              fi
          done
        '';
      };
    };
  };
  systemd.user.timers.nix-remove-old-profiles = {
    Unit.Description = "Delete old Nix profiles weekly";
    Timer = {
      # Randomly picked.
      OnCalendar = "Tue 09:33:38";
      AccuracySec = "24h";
      Persistent = true;
      RandomizedDelaySec = "1h";
    };
  };
}
