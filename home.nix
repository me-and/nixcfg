{ config, lib, pkgs, ... }:

let
  nixOSconfig = (import <nixos/nixos> { }).config;
  nixOSstateVersion = nixOSconfig.system.stateVersion;

  python = pkgs.python3.withPackages (pp: [
    # dateutil needed for asmodeus
    pp.dateutil
  ]);
in {
  imports = [
    ./local-config.nix
    ./git
    ./homeshick.nix
  ]
  ++ lib.optional (builtins.pathExists ~/.config/home-manager-work) ~/.config/home-manager-work;

  warnings = lib.optional ((builtins.pathExists /etc/nixos) && (nixOSstateVersion != config.home.stateVersion)) ''
    Different state versions for nixos (${nixOSstateVersion}) and Home Manager
    (${config.home.stateVersion}).
  '';

  home = {
    username = "adam";
    homeDirectory = "/home/adam";

    packages = with pkgs; [
      fzf
      gh
      jq
      lesspipe
      mosh
      nix-diff
      psmisc
      python
      silver-searcher
      taskwarrior

      # Use the Git version specified by the branch name.
      config.programs.git.package
    ];

    sessionVariables = {
      PYTHONPATH = "${python}/${python.sitePackages}";
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
      { url = "https://github.com/maklt/plantuml-syntax"; link = false; }
      { url = "https://github.com/luochen1990/rainbow"; link = false; }
      { url = "https://github.com/junegunn/vim-openscad"; link = false; }
      { url = "https://github.com/junegunn/vim-plug"; link = false; }
      { url = "https://github.com/lervag/vimtex"; link = false; }
    ];
  };

  # Don't enable Git -- that also enables Home Manager managing Git config,
  # where I want to keep managing my Git config with Homeshick -- but do set
  # the branch to use.
  programs.git.sourceBranch = "next";

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
