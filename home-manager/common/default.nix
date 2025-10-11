{
  flake,
  config,
  lib,
  pkgs,
  ...
}: let
in {
  imports = builtins.attrValues (flake.self.lib.dirfiles {
    dir = ./.;
    excludes = ["default.nix"];
  });

  home = {
    homeDirectory = lib.mkDefault "/home/${config.home.username}";

    # We *don't* add home-manager here, nor use home-manager.enable, because we
    # want to use the system home-manager installation.  In particular, that
    # avoids inconsistent Home Manager and NixOS installation versions when
    # there's a new NixOS release.
    packages = with pkgs;
      [
        alejandra
        ascii
        bintools
        dig.dnsutils
        dos2unix
        fzf
        gh
        git-filter-repo
        gnumake
        htop
        jq
        lesspipe
        lsof
        man-pages
        moreutils
        mosh
        ncdu
        nix-diff
        nix-output-monitor
        nixos-generators
        nixpkgs-review
        psmisc
        pv
        shellcheck
        silver-searcher
        tmux
        tmux-xpanes
        unzip
      ]
      ++ (with pkgs.mypkgs; [
        aaisp-quota
        coldiff
        file-age
        final-eol
        git-report
        mtimewait
        nix-about
        nix-dangling-roots
        nix-locate-bin
        tmux-taskloop
        toil
      ]);

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
      ExecStart = pkgs.mypkgs.writeCheckedShellScript {
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

  nixpkgs.overlays = builtins.attrValues flake.self.overlays;
}
