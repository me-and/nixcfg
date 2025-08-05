{
  config,
  lib,
  pkgs,
  ...
}: let
in {
  imports = [
    ../../common
    ./bash
    ./email.nix
    ./firefox.nix
    ./git.nix
    ./jq
    ./homeshick.nix
    ./host.nix
    ./keepassxc.nix
    ./python.nix
    ./syncthing.nix
    ./taskwarrior
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
      shellcheck
      silver-searcher
      tmux
      tmux-taskloop
      tmux-xpanes
      toil
      unzip
    ];

    sessionVariables = {
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

      # Use a XDG-style path for Unison.
      UNISON = "${config.xdg.stateHome}/unison";
    };
  };

  programs.ssh = {
    enable = true;
    addKeysToAgent = "yes";
  };
  services.ssh-agent.enable = true;

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
      OnCalendar = "weekly";
      AccuracySec = "24h";
      Persistent = true;
      RandomizedDelaySec = "1h";
      RandomizedOffsetSec = "1w";
    };
  };
}
