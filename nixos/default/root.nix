# Configuration for the root user.
{ inputs, config, ... }:
{
  users.users.root.hashedPasswordFile = "/etc/nixos/secrets/root";

  home-manager.users.root =
    {
      lib,
      osConfig,
      ...
    }:
    {
      home.stateVersion = osConfig.system.stateVersion;

      imports = [ inputs.self.homeModules.git ];

      programs.git = {
        enable = true;

        # Use the same as the system package; if I'm doing anything clever
        # anywhere else I want to limit it to user accounts.
        package = osConfig.programs.git.package;
      };

      # Want gh in path so root can call `gh auth login`.  This also
      # automatically enables using gh as a Git authentication helper.
      programs.gh.enable = true;

      # Check nothing has "helpfully" created ~/.gitconfig, as I've seen that
      # happen with some Git credential helpers (GitHub CLI, possibly?) and it'll
      # get in the way of using ~/.config/git/config as Home Manager will set up.
      #
      # This broadly emulates the code in the check-link-targets.sh script that
      # Home Manager uses to install files, except we don't want to install
      # anything.
      #
      # TODO Submit this to Home Manager?
      home.activation = {
        checkForLegacyGitConfig = lib.hm.dag.entryBefore [ "writeBoundary" ] ''
          check_for_legacy_git_config () {
              local collision=
              local source_path="$newGenPath/home-files/.config/git/config"
              local target_path="$HOME/.gitconfig"

              verboseEcho "check_for_legacy_git_config:"
              verboseEcho "  source_path=$source_path"
              verboseEcho "  target_path=$target_path"
              verboseEcho "  HOME_MANAGER_BACKUP_EXT=''${HOME_MANAGER_BACKUP_EXT-not set}"

              if [[ -e "$target_path" && -e "$source_path" ]]; then
                  if [[ "''${HOME_MANAGER_BACKUP_EXT-}" && ! -L "$target_path" ]]; then
                      local backup="$target_path.$HOME_MANAGER_BACKUP_EXT"
                      if [[ -e "$backup" ]]; then
                          errorEcho "Existing file '$backup' would be clobbered by backing up '$target_path'"
                          collision=Yes
                      else
                          warnEcho "Existing file '$target_path' will override '$source_path', will be moved to '$backup'"
                      fi
                  else
                      errorEcho "Existing file '$target_path' will override '$source_path'"
                      collision=Yes
                  fi

                  if [[ "$collision" ]]; then
                      errorEcho "Please do one of the following:"
                      errorEcho "- Move or remove the above file and try again."
                      errorEcho "- In standalone mode, use 'home-manager switch -b backup' to back up"
                      errorEcho "  files automatically"
                      errorEcho "- When used as a NixOS or nix-darwin module, set"
                      errorEcho "    'home-manager.backupFileExtension'"
                      errorEcho "  to, for example, 'backup' and rebuild."
                      return 1
                  fi
              fi
          }

          check_for_legacy_git_config
        '';

        removeLegacyGitConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          remove_legacy_git_config () {
              local collision=
              local source_path="$newGenPath/home-files/.config/git/config"
              local target_path="$HOME/.gitconfig"

              verboseEcho "remove_legacy_git_config:"
              verboseEcho "  source_path=$source_path"
              verboseEcho "  target_path=$target_path"
              verboseEcho "  HOME_MANAGER_BACKUP_EXT=''${HOME_MANAGER_BACKUP_EXT-not set}"

              if [[ -e "$target_path" && -e "$source_path" && ! -L "$target_path" && "''${HOME_MANAGER_BACKUP_EXT-}" ]]
              then
                  local backup="$target_path.$HOME_MANAGER_BACKUP_EXT"
                  run mv --no-clobber $VERBOSE_ARG "$target_path" "$target_path.$HOME_MANAGER_BACKUP_EXT"
              fi
          }

          remove_legacy_git_config
        '';
      };
    };

  # Delete old Nix profiles for root automatically, since I'll not be logging
  # in regularly to check for them.
  #
  # TODO Is this necessary given my current nix-gc.service configuration?
  systemd.services.nix-remove-old-root-profiles = {
    description = "Delete old Nix profiles for root";
    serviceConfig.Type = "oneshot";
    script = ''
      for p in /nix/var/nix/profiles/per-user/root/*; do
          if [[ "$p" =~ (.*)-[0-9]+-link ]] &&
              [[ -e "''${BASH_REMATCH[1]}" ]]
          then
              # This is a version of a profile, so ignore it
              :
          else
              ${config.nix.package.out}/bin/nix-env --delete-generations 180d -p "$p"
          fi
      done
    '';
  };
  systemd.timers.nix-remove-old-root-profiles = {
    description = "Delete old Nix profiles for root weekly";
    timerConfig = {
      OnCalendar = "weekly";
      AccuracySec = "24h";
      Persistent = true;
      RandomizedDelaySec = "1h";
      RandomizedOffsetSec = "1w";
    };
  };
}
