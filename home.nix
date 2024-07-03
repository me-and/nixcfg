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

  myPkgs = pkgs.callPackage ./mypackages.nix {};

  isWsl =
    (builtins.pathExists /proc/sys/fs/binfmt_misc/WSLInterop)
    || (builtins.pathExists /proc/sys/fs/binfmt_misc/WSLInterop-late);
  windowsHomeDir = builtins.readFile (
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
      ./systemd
    ]
    ++ (
      lib.optional (builtins.pathExists ~/.config/home-manager-work)
      ~/.config/home-manager-work
    );

  home = {
    username = "adam";
    homeDirectory = "/home/adam";

    packages = let
      nixpkgs = with pkgs; [
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
        ncdu
        nix-diff
        nix-locate-bin
        psmisc
        pv
        python
        silver-searcher
        taskwarrior
      ];
      mypkgs = with myPkgs; [
        mtimewait
        nix-about
        toil
      ];
    in
      nixpkgs
      ++ mypkgs
      # Use the Git version possibly configured in local-config.nix.  This is
      # handled here rather than with config.programs.git.enable because that
      # would also result in Home Manager trying to manage my Git config, which
      # I'm not (yet) ready for.
      ++ [config.programs.git.package];

    sessionVariables = {
      # Ideally this wouldn't be handled here but instead by Nix dependency
      # management -- nothing should rely on the general site environment being
      # set up correctly -- but this is the quick solution while there are
      # plenty of things I care about that aren't yet integrated into Home
      # Manager.
      PYTHONPATH = "${python}/${python.sitePackages}";
    };

    file = lib.mkIf isWsl {
      WinHome = {source = mkOutOfStoreSymlink windowsHomeDir;};
      ".bashrc.d/winget" = {text = "alias winget=winget.exe";};
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
