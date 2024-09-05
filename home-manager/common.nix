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

  # Avoid using lib for this, so it can be safely used with imports.
  fileIfExtant = file:
    if builtins.pathExists file
    then [file]
    else [];
in {
  imports =
    [
      ../modules/home-manager
      ../modules/shared
    ]
    ++ fileIfExtant ../local-config.nix;

  home = {
    username = lib.mkDefault "adam";
    homeDirectory = lib.mkDefault "/home/adam";

    packages = with pkgs; [
      alejandra
      ascii
      coldiff
      dig.dnsutils
      dos2unix
      fzf
      gh
      git-filter-repo
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
      nix-diff
      nix-locate-bin
      psmisc
      pv
      python
      silver-searcher
      taskwarrior
      taskloop
      tmux
      tmux-taskloop
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
      (dontLink "https://github.com/me-and/asmodeus")
      (dontLink "https://github.com/magicmonty/bash-git-prompt")
    ];
  };
}
