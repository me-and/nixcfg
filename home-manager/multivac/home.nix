{
  config,
  lib,
  ...
}: let
  systemdWantsAlias = baseUnit: instanceUnit: from: {
    ".config/systemd/user/${from}.wants/${instanceUnit}".source = config.home.file.".config/systemd".source + "/user/${baseUnit}";
  };
  systemdWants = unit: systemdWantsAlias unit unit;
  systemdWantsInstance = unit: instance: let
    instanceUnit = builtins.replaceStrings ["@."] ["@${instance}."] unit;
  in
    systemdWantsAlias unit instanceUnit;

  homeshickReportUnit = instance: systemdWantsInstance "homeshick-pull@.service" instance "homeshick-report.service";
in {
  imports = [../common];

  home.stateVersion = "24.05";

  # Enable all the systemd units I want running.  These are mostly coming from
  # the user-systemd-config GitHub repo, which isn't integrated into Nix and
  # therefore everything needs to be done manually.
  home.file = lib.attrsets.mergeAttrsList [
    (homeshickReportUnit "bash\\x2dgit\\x2dprompt")
    (homeshickReportUnit "homeshick")

    (systemdWants "disk-usage-report.timer" "timers.target")
  ];

  #programs.git.package = pkgs.git-tip;

  pd.enable = true;

  accounts.email.forwardLocal.enable = true;
}
