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

  # Avoid using lib for this, so it can be safely used with imports.
  fileIfExtant = file:
    if builtins.pathExists file
    then [file]
    else [];
in {
  imports =
    [
      ../../common
      ./firefox.nix
      ./keepassxc.nix
      ./taskwarrior.nix
      ../../modules/home-manager
      ../../modules/shared
    ]
    ++ fileIfExtant ../../local-config.nix;

  home = {
    username = lib.mkDefault "adam";
    homeDirectory = lib.mkDefault "/home/adam";

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
      taskloop
      tmux
      tmux-taskloop
      tmux-xpanes
      toil
      unzip

      # Use the Git version possibly configured in local-config.nix.  This is
      # handled here rather than with config.programs.git.enable because that
      # would also result in Home Manager trying to manage my Git config, which
      # I'm not (yet) ready for.
      config.programs.git.package
    ];

    sessionVariables = {
      # Ideally this wouldn't be handled here but instead by Nix dependency
      # management -- nothing should rely on the general site environment being
      # set up correctly -- but this is the quick solution while there are
      # plenty of things I care about that aren't yet integrated into Home
      # Manager.
      PYTHONPATH = "${python}/${python.sitePackages}";
    };

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
      (dontLink "https://github.com/me-and/nixcfg")
      (dontLink "https://github.com/me-and/asmodeus")
      (dontLink "https://github.com/magicmonty/bash-git-prompt")
    ];
  };
}
