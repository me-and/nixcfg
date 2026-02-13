{
  config,
  lib,
  pkgs,
  ...
}:
{
  home = {
    homeDirectory = lib.mkDefault "/home/${config.home.username}";

    # We *don't* add home-manager here, nor use home-manager.enable, because we
    # want to use the system home-manager installation.  In particular, that
    # avoids inconsistent Home Manager and NixOS installation versions when
    # there's a new NixOS release.
    packages =
      with pkgs;
      [
        ascii
        bintools
        dig.dnsutils
        dos2unix
        fzf
        git-filter-repo
        gnumake
        htop
        jq
        lesspipe
        lsof
        man-pages
        moreutils
        ncdu
        nix-diff
        nix-output-monitor
        nixfmt-tree
        nixos-generators
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
        dirup
        file-age
        final-eol
        git-report
        mosh
        mtimewait
        nix-about
        nix-dangling-roots
        nix-locate-bin
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
    enableDefaultConfig = false;
    matchBlocks."*".addKeysToAgent = "yes";
  };
  services.ssh-agent.enable = true;

  xdg.enable = true;
  xdg.autostart.enable = true;
}
