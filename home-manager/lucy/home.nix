{
  config,
  lib,
  pkgs,
  personalCfg,
  ...
}:
let
  systemdWantsAlias = baseUnit: instanceUnit: from: {
    ".config/systemd/user/${from}.wants/${instanceUnit}".source =
      config.home.file.".config/systemd".source + "/user/${baseUnit}";
  };
  systemdWants = unit: systemdWantsAlias unit unit;
  systemdWantsInstance =
    unit: instance:
    let
      instanceUnit = builtins.replaceStrings [ "@." ] [ "@${instance}." ] unit;
    in
    systemdWantsAlias unit instanceUnit;

  systemdWantsService = name: systemdWants "${name}.service" "default.target";
  systemdWantsTimer = name: systemdWants "${name}.timer" "timers.target";
  systemdWantsPath = name: systemdWants "${name}.path" "paths.target";

  systemdServiceSymlinks = map systemdWantsService [ ];
  systemdTimerSymlinks = map systemdWantsTimer [
    "disk-usage-report"
    "report-onedrive-conflicts"
    "taskwarrior-monthly"
    "taskwarrior-project-check"
  ];
  systemdPathSymlinks = map systemdWantsPath [
    "taskwarrior-dinwoodie.org-emails"
    "sign-petitions"
  ];

  systemdSymlinks = lib.mergeAttrsList (
    systemdServiceSymlinks ++ systemdTimerSymlinks ++ systemdPathSymlinks
  );
in
{
  imports = [ personalCfg.homeModules.latex ];
  home.stateVersion = "25.11";

  # Enable all the systemd units I want running.  These are mostly coming from
  # the user-systemd-config GitHub repo, which isn't integrated into Nix and
  # therefore everything needs to be done manually.
  home.file = lib.mkIf config.systemd.user.enable systemdSymlinks;

  home.packages = [
    pkgs.mypkgs.wavtoopus
    pkgs.quodlibet-without-gst-plugins # operon
  ];

  systemd.user.timers = {
    "offlineimap-full@main" = {
      Unit.Description = "Daily sync of all labels for account main";
      Install.WantedBy = [ "timers.target" ];
      Timer.OnCalendar = "06:00";
      Timer.RandomizedDelaySec = "1h";
      Timer.AccuracySec = "1h";
    };
  };

  services.rclone.enable = true;
  services.rclone.mountPoints = {
    "${config.home.homeDirectory}/OneDrive" = "onedrive:";
  };

  accounts.email.maildirBasePath = "${config.xdg.cacheHome}/mail";
  programs.offlineimap.enable = true;
  programs.neomutt.enable = true;

  services.syncthing.enable = true;

  programs.taskwarrior.onedriveBackup = true;
}
