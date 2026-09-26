{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.taskwarrior;
  syncConfigured = (cfg.config.taskd.server or "") != "";
in
{
  options.programs.taskwarrior.checkGitHubIssues.enable =
    lib.mkEnableOption "regularly checking for open GitHub issues/PRs that are missing Taskwarrior tasks";

  config = lib.mkIf cfg.checkGitHubIssues.enable {
    systemd.user = {
      services.taskwarrior-github-check = {
        Unit = {
          Description = "Check GitHub issue and PR tracking in Taskwarrior";
          Wants = lib.mkIf syncConfigured [ "taskwarrior-sync.service" ];
          After = lib.mkIf syncConfigured [ "taskwarrior-sync.service" ];
          OnSuccess = lib.mkIf syncConfigured [ "taskwarrior-sync.service" ];
        };
        Service.Type = "oneshot";
        Service.Environment =
          let
            runtimeInputs = [
              config.programs.taskwarrior.package
              pkgs.privatepkgs.gh-report-issues
            ];
          in
          [ "PATH=${lib.makeBinPath runtimeInputs}" ];
        Service.ExecStart = "${lib.getExe pkgs.mypkgs.pythonWithAsmodeus} ${./github_issues.py}";
      };

      timers.taskwarrior-github-check = {
        Unit.Description = "Check GitHub issue and PR tracking in Taskwarrior daily";
        Install.WantedBy = [ "timers.target" ];
        Timer = {
          OnActiveSec = "0s";
          OnUnitActiveSec = "30min";
          AccuracySec = "1h";
          RandomizedDelaySec = "1h";
        };
      };
    };
  };
}
