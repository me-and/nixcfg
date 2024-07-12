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

  homeshickInit = pkgs.writeCheckedShellScript {
    name = "homeshick-init.sh";
    runtimeInputs = with pkgs; [config.programs.git.package gh coreutils bash];
    text = ''
      set -euo pipefail

      link_mode=
      if [[ "$1" = -l ]]; then
          link_mode='link'
          shift
      elif [[ "$1" = -f ]]; then
          link_mode='force'
          shift
      fi

      declare -r link_mode
      declare -r dest="$1"
      declare -r url="$2"

      if [[ ! -d "$HOME"/.homesick/repos/"$dest" ]]; then
          git clone "$url" ~/.homesick/repos/"$dest"
      fi

      set -x
      if [[ "$link_mode" ]]; then
          homeshick () {
              ~/.homesick/repos/${cfg.homeshick.dest}/bin/homeshick "$@"
          }
          if [[ "$link_mode" = link ]]; then
              homeshick --skip link "$dest"
          elif [[ "$link_mode" = force ]]; then
              homeshick --force link "$dest"
          else
              echo "Unexpected link mode $link_mode" >&2
              exit 1
          fi
      fi
    '';
  };

  homeshickUnit = {
    dest,
    description,
    url,
    link,
    forceLink,
    after ? ["homeshick.service"],
  }: let
    shellArgs =
      (
        if !link
        then []
        else if forceLink
        then ["-f"]
        else ["-l"]
      )
      ++ [dest url];
  in {
    Unit.Description = description;
    Unit.After = after;
    Service.Type = "oneshot";
    Service.ExecStart = "${homeshickInit} ${lib.strings.escapeShellArgs shellArgs}";
    Install.WantedBy = ["default.target"];
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
  };

  config = lib.mkIf cfg.enable {
    systemd.user.services =
      {
        homeshick = homeshickUnit {
          inherit (cfg.homeshick) dest url link forceLink;
          description = "Homeshick installation";
          after = [];
        };
      }
      // (
        lib.attrsets.mergeAttrsList (map (h: {
            "homeshick@${h.dest}" = homeshickUnit {
              inherit (h) dest url link forceLink;
              description = "Homeshick %i installation";
            };
          })
          cfg.repos)
      );

    nixpkgs.overlays = [(import ../../overlays/checkedshellscript.nix)];
  };
}
