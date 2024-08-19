{
  config,
  lib,
  options,
  pkgs,
  ...
}: let
  cfg = config.homeshick;

  castleOpts = {config, ...}: {
    options = {
      url = lib.mkOption {
        type = lib.types.str;
        description = "URL of the Git repository to clone.";
      };
      dest = lib.mkOption {
        type = lib.types.str;
        description = ''
          The subdirectory of ~/.homesick/repos to clone into.  If undefined
          the destination will be taken from the URL.
        '';
      };
      link = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Whether to run `homeshick link` with this repository.";
      };
      forceLink = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Whether to overwrite existing files when linking.";
      };
    };

    config = {
      dest = lib.mkDefault (
        lib.lists.last (
          lib.strings.split "/" (lib.strings.removeSuffix ".git" config.url)
        )
      );
    };
  };

  defaultHomeshickRepo = {
    url = "https://github.com/andsens/homeshick";
    link = false;
  };
in {
  options.homeshick = {
    enable = lib.mkEnableOption "Homeshick";

    homeshick = lib.mkOption {
      type = lib.types.submodule castleOpts;
      default = defaultHomeshickRepo;
      description = "The repository that contains Homeshick itself.";
    };

    repos = lib.mkOption {
      type = lib.types.listOf (lib.types.submodule castleOpts);
      description = "Other Homeshick repositories to configure.";
      default = [];
      example = [
        {url = "https://github.com/me-and/castle";}
      ];
    };

    extraPackages = lib.mkOption {
      description = ''
        Extra packages required to clone your Git Homeshick repositories, for
        example to provide authentication for private repositories.
      '';
      type = lib.types.listOf (lib.types.package);
      default = [];
      example = [pkgs.gh];
    };
  };

  config = lib.mkIf cfg.enable {
    home.activation.homeshick = let
      runtimeInputs =
        [
          config.programs.git.package
          pkgs.coreutils
          pkgs.bash
        ]
        ++ cfg.extraPackages;
      repoInit = castleCfg: let
        linkArg =
          if castleCfg.forceLink
          then "--force"
          else "--skip";
      in
        ''
          dest=${lib.escapeShellArg castleCfg.dest}
          if [[ -d "$HOME"/.homesick/repos/"$dest" ]]; then
              noteEcho "Skipping extant repository $dest"
          else
              run git clone ${lib.escapeShellArg castleCfg.url} "$HOME"/.homesick/repos/"$dest"
          fi
        ''
        + lib.optionalString castleCfg.link ''
          run "$HOME"/.homesick/repos/${lib.escapeShellArg cfg.homeshick.dest}/bin/homeshick \
              ${linkArg} link "$dest"
        '';
    in
      lib.hm.dag.entryAfter ["writeBoundary"] (
        ''
          oldpath="$PATH"
          PATH=${lib.makeBinPath runtimeInputs}"''${PATH:+:"$PATH"}"
        ''
        + lib.concatStrings (map repoInit ([cfg.homeshick] ++ cfg.repos))
        + ''
          PATH="$oldpath"
        ''
      );
  };
}
