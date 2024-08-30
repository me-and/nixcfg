{
  config,
  lib,
  pkgs,
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

  homeshickReportWants = dir: systemdWantsInstance "homeshick-pull@.service" dir "homeshick-report.service";

  systemdWantsService = name: systemdWants "${name}.service" "default.target";
  systemdWantsTimer = name: systemdWants "${name}.timer" "timers.target";
  systemdWantsPath = name: systemdWants "${name}.path" "paths.target";

  systemdServiceSymlinks = map systemdWantsService [
    "ssh-agent"
    "taskwarrior-gc"
    "taskwarrior-sync"
  ];
  systemdHomeshickReportSymlinks = map homeshickReportWants [
    "bash\\x2dgit\\x2dprompt"
    "homeshick"
  ];
  systemdTimerSymlinks =
    (
      map systemdWantsTimer [
        "disk-usage-report"
        "homeshick-report"
        "report-onedrive-conflicts"
        "taskwarrior-gc"
        "taskwarrior-inbox"
        "taskwarrior-monthly"
        "taskwarrior-project-check"
        "taskwarrior-sync"
      ]
    )
    ++ [(systemdWantsInstance "offlineimap-full@.timer" "adam\\x40dinwoodie.org" "timers.target")];
  systemdPathSymlinks = map systemdWantsPath [
    "taskwarrior-dinwoodie.org-emails"
    "sign-petitions"
  ];

  systemdSymlinks = lib.mergeAttrsList (
    systemdServiceSymlinks
    ++ systemdHomeshickReportSymlinks
    ++ systemdTimerSymlinks
    ++ systemdPathSymlinks
  );
in {
  imports = [./common.nix];

  home.stateVersion = "24.05";

  # Enable all the systemd units I want running.  These are mostly coming from
  # the user-systemd-config GitHub repo, which isn't integrated into Nix and
  # therefore everything needs to be done manually.
  home.file = lib.mkIf config.systemd.user.enable systemdSymlinks;

  services.rclone.enable = true;
  services.rclone.mountPoints = {
    "${config.home.homeDirectory}/OneDrive" = "onedrive:";
  };

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

  # Configure accounts.email.accounts.*.address in local-config.nix.
  accounts.email.accounts.main = {
    flavor = "gmail.com";
    folders = {
      inbox = "INBOX";
      drafts = "[Gmail]/Drafts";
      sent = "[Gmail]/Sent Mail";
      trash = "[Gmail]/Bin";
    };
    # TODO configure this?
    #maildir.path = config.accounts.email.accounts.main.address;
    # TODO configure this, with all the attentant options
    #neomutt.enable = true;
    # TODO configure this, with all the attendant options
    #offlineimap.enable = true;
    primary = true;
    realName = "Adam Dinwoodie";
  };
  accounts.email.maildirBasePath = "${config.xdg.cacheHome}/mail";
  accounts.email.forwardLocal.enable = true;

  #programs.git.package = pkgs.git-tip;

  home.packages = [pkgs.offlineimap];
}