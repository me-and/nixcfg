{
  config,
  lib,
  pkgs,
  ...
}: let
  python = pkgs.python3.withPackages (pp: [
    # dateutil needed for asmodeus
    pp.dateutil
  ]);

  fileIfExtant = file: lib.optional (builtins.pathExists file) file;
in {
  imports =
    [
      ./local-config.nix
      ./modules/home-manager
      ./modules/shared
    ]
    ++ fileIfExtant ~/.config/home-manager-work;

  home = {
    username = lib.mkDefault "adam";
    homeDirectory = lib.mkDefault "/home/adam";

    packages = with pkgs; [
      alejandra
      ascii
      dos2unix
      fzf
      gh
      git-filter-repo
      htop
      jq
      lesspipe
      moreutils
      mosh
      mtimewait
      ncdu
      nix-about
      nix-diff
      nix-locate-bin
      psmisc
      pv
      python
      screen
      silver-searcher
      taskwarrior
      toil

      # This is in place of setting programs.home-manager.enable, since that
      # doesn't pick up my overlay.
      home-manager

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
      (dontLink "https://github.com/mileszs/ack.vim")
      (dontLink "https://github.com/me-and/asmodeus")
      (dontLink "https://github.com/magicmonty/bash-git-prompt")
      (dontLink "https://github.com/vito-c/jq.vim")
      (dontLink "https://github.com/aklt/plantuml-syntax")
      (dontLink "https://github.com/luochen1990/rainbow")
      (dontLink "https://github.com/sirtaj/vim-openscad")
      (dontLink "https://github.com/junegunn/vim-plug")
      (dontLink "https://github.com/junegunn/fzf.vim")
      (dontLink "https://github.com/lervag/vimtex")
    ];
  };
}
