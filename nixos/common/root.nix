# Configuration for the root user.
{
  config,
  lib,
  ...
}: {
  home-manager.users.root = {
    home.stateVersion = config.system.stateVersion;

    programs.git = {
      enable = true;

      # Use the same as the system package; if I'm doing anything clever
      # anywhere else I want to limit it to user accounts.
      package = config.programs.git.package;

      aliases = {
        pwl = "push --force-with-lease";
        lug = "log -u";
        lol = "log --graph --decorate --pretty=oneline --abbrev-commit";
        lola = "log --graph --decorate --pretty=oneline --abbrev-commit --all";
        lols = "log --graph --decorate --pretty=oneline --abbrev-commit --stat";
        lolas = "log --graph --decorate --pretty=oneline --abbrev-commit --stat --all";
        stashed = "!f () { git stash save && \"$@\" && git stash pop; }; f";
      };

      userName = "Adam Dinwoodie";
      userEmail = lib.mkDefault (throw "Set home-manager.users.root.programs.git.userEmail in local-config.nix");

      extraConfig = {
        pull.rebase = false;
      };
    };

    # Want gh in path so root can call `gh auth login`.  This also
    # automatically enables using gh as a Git authentication helper.
    programs.gh.enable = true;
  };
}
