# Common Home Manager Git configuration that is pulled in by the default Home
# Manager profile *and also* the root user's Home Manager profile configured in
# the NixOS configurations.
{ config, lib, ... }:
let
  mainEmailAccount = config.accounts.email.primaryAccount or null;
in
{
  programs.git = {
    enable = true;

    ignores = [
      # Vim swap files
      ".*.swp"
      ".swp"

      # Cscope files
      "cscope.out"
      "cscope.po.out"
      "cscope.in.out"

      # Python binaries
      "*.pyc"
      "*.pyo"
    ];

    settings = {
      alias = {
        # Simple short forms
        h = "help";

        # More complicated shortcuts
        about = "describe --all --always";
        raw = "show --format=raw";
        full = "show --format=full";
        fuller = "show --format=fuller";
        amend = "commit --amend -C HEAD";
        ita = "add --intent-to-add";
        rm-cur-br = "!f() { br=\"$(git symbolic-ref --short HEAD)\" && git detach && if [[ \"$1\" = -D ]]; then git branch -D \"$br\"; else git branch -d \"$br\"; fi; }; f";
        detach = "checkout --detach";
        pullout = "!f() { git switch -C \"$1\" \"$1\"@{u}; }; f";
        pwl = "push --force-with-lease";

        # Logs
        lug = "log -u";
        lol = "log --graph --decorate --pretty=oneline --abbrev-commit";
        lola = "log --graph --decorate --pretty=oneline --abbrev-commit --all";
        lols = "log --graph --decorate --pretty=oneline --abbrev-commit --stat";
        lolas = "log --graph --decorate --pretty=oneline --abbrev-commit --all --stat";
        bivis = "bisect visualize --graph --decorate --pretty=oneline --abbrev-commit";

        # Repo information
        list-all-objs = "!f() { { git rev-list --objects --all; git rev-list --objects -g --all; git rev-list --objects $(git fsck --unreachable | grep '^unreachable' | cut -d' ' -f3); } | cut -d' ' -f1 | sort -u; }; f";
        roots = "log --max-parents=0 --pretty=format:%H";

        # Conflict handling
        conflicts = "!git -C \"\${GIT_PREFIX:-.}\" ls-files --unmerged | cut -f2 | sort -u";

        # Use to stash the current changes, perform an operation, then unstash
        # them.  In particular, `git stashed !!` works in place of `git stash
        # push && !! && git stash pop`.
        stashed = "!f() { git stash save && \"$@\" && git stash pop; }; f";

        # Fix the email address in the last commit.
        fix-email = "!f() { git config user.email \"$1\" && git commit --amend --reset-author --no-edit; }; f";

        # Other useful commands.
        git-ml-describe = "show -s --pretty=reference";
        mydescribe = "show -s --pretty='format:%h (\"%s\")'";
      };

      core.pager = "less -S";
      diff = {
        algorithm = "patience";
        interHunkContext = 6;
      };
      difftool.prompt = false;
      grep.lineNumber = true;
      init.defaultBranch = "main";
      log = {
        decorate = "short";
        mailmap = true;
      };
      mergetool.prompt = false;
      pull.ff = "only";
      push = {
        default = "tracking";
        autoSetupRemote = true;
      };
      rebase.autoSquash = true;
      rerere.enabled = true;
      sendemail = {
        confirm = "always";
        annotate = true;
        suppresscc = "self";
        envelopeSender = "auto";
      };
      svn.pushmergeinfo = true;
      url = {
        "https://gist.github.com/".insteadOf = "git://gist.github.com/";
        "https://github.com/".insteadOf = "git://github.com/";
      };
      user = {
        name = "Adam Dinwoodie";
        email = lib.mkIf (mainEmailAccount != null) mainEmailAccount.address;
      };
    };
  };
}
