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

  systemdWantsTimer = name: systemdWants "${name}.timer" "timers.target";

  systemdServiceSymlinks = [ ];
  systemdTimerSymlinks = map systemdWantsTimer [
    "disk-usage-report"
  ];
  systemdPathSymlinks = [ ];

  systemdSymlinks = lib.mergeAttrsList (
    systemdServiceSymlinks ++ systemdTimerSymlinks ++ systemdPathSymlinks
  );
in
{
  imports = [ personalCfg.homeModules.latex ];

  home.stateVersion = "25.11";

  home.packages = with pkgs; [
    poppler-utils
    mypkgs.pd-sync-with-fileserver
    mypkgs.unison-nox
  ];

  # Enable all the systemd units I want running.  These are mostly coming from
  # the user-systemd-config GitHub repo, which isn't integrated into Nix and
  # therefore everything needs to be done manually.
  home.file = lib.mkIf config.systemd.user.enable systemdSymlinks;
}
