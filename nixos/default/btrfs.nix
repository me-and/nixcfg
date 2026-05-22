{
  config,
  lib,
  pkgs,
  mylib,
  ...
}:
let
  inherit (builtins) listToAttrs;

  fsList = builtins.attrValues config.fileSystems;
  fsIsBtrfs = fs: fs.fsType == "btrfs";
  hasBtrfs = lib.any fsIsBtrfs fsList;
  cfgScrub = config.services.btrfs.autoScrub;
  scrubFileSystems = cfgScrub.fileSystems;

  mkScrubTimerOverrides =
    fs:
    let
      fs' = mylib.escapeSystemdPath fs;
    in
    lib.nameValuePair "btrfs-scrub-${fs'}" {
      timerConfig = {
        RandomizedOffsetSec = "30d";
        RandomizedDelaySec = "10min";
      };
    };

  mkBalanceService =
    fs:
    let
      fs' = mylib.escapeSystemdPath fs;
      balanceScript = pkgs.mypkgs.writeCheckedShellScript {
        name = "btrfs-balance-${fs'}";
        runtimeInputs = [ pkgs.btrfs-progs ];
        text = ''
          btrfs balance start -dusage=10 -musage=10 ${lib.escapeShellArg fs}
        '';
      };
    in
    lib.nameValuePair "btrfs-balance-${fs'}" {
      description = "btrfs balance on ${fs}";
      documentation = [ "man:btrfs-balance(8)" ];
      # Like scrub, balance can block suspend/shutdown for a long time.
      conflicts = [
        "shutdown.target"
        "sleep.target"
      ];
      before = [
        "shutdown.target"
        "sleep.target"
      ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = balanceScript;
        CPUSchedulingPolicy = "idle";
        IOSchedulingClass = "idle";
        Nice = 19;
      };
    };

  mkResumeService =
    fs:
    let
      fs' = mylib.escapeSystemdPath fs;
      resumeScript = pkgs.mypkgs.writeCheckedShellScript {
        name = "btrfs-maintenance-resume-${fs'}";
        runtimeInputs = [ pkgs.btrfs-progs ];
        text = ''
          resume_or_ignore_not_running() {
            local op="$1"
            shift

            if "$@"; then
              return 0
            fi

            local rc="$?"
            if [[ "$rc" -eq 2 ]]; then
              return 0
            fi

            printf 'failed to resume %s on %s (exit %s)\n' "$op" ${lib.escapeShellArg fs} "$rc" >&2
            return "$rc"
          }

          resume_or_ignore_not_running scrub btrfs scrub resume -B ${lib.escapeShellArg fs}
          resume_or_ignore_not_running balance btrfs balance resume ${lib.escapeShellArg fs}
        '';
      };
    in
    lib.nameValuePair "btrfs-maintenance-resume-${fs'}" {
      description = "Resume interrupted btrfs scrub/balance on ${fs}";
      after = [ "local-fs.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = resumeScript;
        CPUSchedulingPolicy = "idle";
        IOSchedulingClass = "idle";
        Nice = 19;
      };
    };

  mkResumeAfterSleepService =
    fs:
    let
      fs' = mylib.escapeSystemdPath fs;
    in
    lib.nameValuePair "btrfs-maintenance-resume-after-sleep-${fs'}" {
      description = "Trigger btrfs maintenance resume after waking from sleep for ${fs}";
      wantedBy = [ "sleep.target" ];
      before = [ "sleep.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStop = "${pkgs.systemd}/bin/systemctl start btrfs-maintenance-resume-${fs'}.service";
      };
      unitConfig.StopWhenUnneeded = true;
    };

  mkBalanceTimer =
    fs:
    let
      fs' = mylib.escapeSystemdPath fs;
    in
    lib.nameValuePair "btrfs-balance-${fs'}" {
      description = "Monthly BTRFS balance timer on ${fs}";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "monthly";
        RandomizedOffsetSec = "30d";
        RandomizedDelaySec = "10min";
        AccuracySec = "1h";
        Persistent = true;
      };
    };

  scrubTimerOverrides = listToAttrs (map mkScrubTimerOverrides scrubFileSystems);
  balanceServices = listToAttrs (map mkBalanceService scrubFileSystems);
  balanceTimers = listToAttrs (map mkBalanceTimer scrubFileSystems);
  resumeServices = listToAttrs (map mkResumeService scrubFileSystems);
  resumeAfterSleepServices = listToAttrs (map mkResumeAfterSleepService scrubFileSystems);
in
lib.mkIf hasBtrfs {
  environment.systemPackages = [ pkgs.btdu ];

  services.btrfs.autoScrub = {
    # Use the upstream NixOS scrub module for service behavior, including
    # suspend/shutdown handling and filesystem deduplication by backing device.
    enable = true;
    interval = "monthly";
  };

  # Deviation from upstream defaults: spread scrub timers across the month and
  # add startup jitter.
  systemd.timers = scrubTimerOverrides // balanceTimers;

  # Deviations from upstream: add a periodic low-usage balance pass and resume
  # interrupted scrub/balance operations after reboot and after waking.
  systemd.services = balanceServices // resumeServices // resumeAfterSleepServices;
}
