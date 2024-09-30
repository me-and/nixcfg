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
  imports = [./common];

  home.stateVersion = "24.05";

  # Enable all the systemd units I want running.  These are mostly coming from
  # the user-systemd-config GitHub repo, which isn't integrated into Nix and
  # therefore everything needs to be done manually.
  home.file = lib.attrsets.mergeAttrsList [
    (systemdWants "ssh-agent.service" "default.target")
    (systemdWants "taskwarrior-gc.service" "default.target")
    (systemdWants "taskwarrior-sync.service" "default.target")

    (homeshickReportUnit "bash\\x2dgit\\x2dprompt")
    (homeshickReportUnit "homeshick")

    (systemdWants "disk-usage-report.timer" "timers.target")
    (systemdWants "homeshick-report.timer" "timers.target")
    (systemdWants "taskwarrior-gc.timer" "timers.target")
    (systemdWants "taskwarrior-sync.timer" "timers.target")
  ];

  # Configure programs.taskwarrior.sync.credentials in local-config.nix.  Not
  # sure this is necessary, but I'd rather have it private than not.
  programs.taskwarrior = {
    enable = true;
    sync = {
      enable = true;
      address = "taskwarrior.dinwoodie.org";
      port = 50340;
      certPath = "${config.xdg.configHome}/task/adam.cert.pem";
      keyPath = "${config.xdg.configHome}/task/adam.key.pem";
    };
  };

  accounts.email.forwardLocal.enable = true;
}
