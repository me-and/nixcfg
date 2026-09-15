{
  config,
  lib,
  pkgs,
  mylib,
  ...
}:
let
  fsList = builtins.attrValues config.fileSystems;
  fsIsBtrfs = fs: fs.fsType == "btrfs";
  hasBtrfs = lib.any fsIsBtrfs fsList;
  cfgScrub = config.services.btrfs.autoScrub;
  scrubFileSystems = cfgScrub.fileSystems;
in
lib.mkIf hasBtrfs {
  environment.systemPackages = [ pkgs.btdu ];

  services.btrfs.autoScrub = {
    # Use the upstream NixOS scrub module for service behavior, including
    # suspend/shutdown handling and filesystem deduplication by backing device.
    enable = true;
    interval = "monthly";
  };

  systemd.timers = {
    # Deviation from upstream defaults: spread scrub timers across the month.
    "btrfs-scrub@".timerConfig.RandomizedOffsetSec = "30d";

    "btrfs-balance@" = {
      description = "Regular btrfs balance on %f";
      documentation = [ "man:btrfs-balance(8)" ];
      timerConfig = {
        OnCalendar = "monthly";
        RandomizedOffsetSec = "30d";
        AccuracySec = "1d";
        Persistent = true;
      };
    };
  };

  # Deviations from upstream: add a periodic low-usage balance pass and resume
  # interrupted scrub/balance operations after reboot and after waking.
  systemd.services = {
    "btrfs-balance@" = {
      description = "btrfs balance on %f";
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
      unitConfig.RequiresMountsFor = [ "%f" ];
      serviceConfig = {
        CPUSchedulingPolicy = "idle";
        IOSchedulingClass = "idle";
        Nice = 19;
        ExecStart =
          let
            script = pkgs.mypkgs.writeCheckedShellScript {
              name = "btrfs-balance.sh";
              runtimeInputs = [ pkgs.btrfs-progs ];
              # Emulate the default balance behaviour from
              # https://github.com/kdave/btrfsmaintenance
              text = ''
                target="$1"

                btrfs filesystem df "$target"
                df -h "$target"

                for n in 0 5 10; do
                    btrfs balance start -dusage="$n" "$target"
                done
                for n in 0 5; do
                    btrfs balance start -musage="$n" "$target"
                done

                btrfs filesystem df "$target"
                df -h "$target"
              '';
            };
          in
          "${script} %f";
        ExecStop =
          let
            script = pkgs.mypkgs.writeCheckedShellScript {
              name = "btrfs-pause-balance.sh";
              runtimeInputs = [ pkgs.btrfs-progs ];
              text = ''
                target="$1"

                if [[ ! -v MAINPID ]]; then
                    # Service has already stopped, so we don't need to do anything
                    # to stop it.
                    exit 0
                fi

                btrfs balance pause "$target"
              '';
            };
          in
          "${script} %f";
      };
    };

    "btrfs-maintenance-resume@" = {
      description = "Resume interrupted btrfs scrub/balance on %f";
      after = [ "local-fs.target" ];
      unitConfig.RequiresMountsFor = [ "%f" ];
      serviceConfig = {
        CPUSchedulingPolicy = "idle";
        IOSchedulingClass = "idle";
        Nice = 19;
        ExecStart =
          let
            script = pkgs.mypkgs.writeCheckedShellScript {
              name = "btrfs-maintenance-resume.sh";
              runtimeInputs = [ pkgs.btrfs-progs ];
              text = ''
                target="$1"

                resume_or_ignore_not_running () {
                    local op="$1"
                    shift

                    if "$@"; then
                        return 0
                    fi

                    local rc="$?"
                    if (( rc == 2 )); then
                        return 0
                    fi

                    printf 'failed to resume %s on %s (exit %s)\n' "$op" "$target" "$rc" >&2
                    return "$rc"
                }

                resume_or_ignore_not_running scrub btrfs scrub resume -B "$target"
                resume_or_ignore_not_running balance btrfs balance resume "$target"
              '';
            };
          in
          "${script} %f";
        ExecStop =
          let
            script = pkgs.mypkgs.writeCheckedShellScript {
              name = "btrfs-maintenance-cancel-resume.sh";
              runtimeInputs = [ pkgs.btrfs-progs ];
              text = ''
                target="$1"

                if [[ ! -v MAINPID ]]; then
                    # Service is already stopped so we don't need to do anything to
                    # stop it.
                    exit 0
                fi

                # `btrfs scrub cancel` saves the current state for a future resume.
                if btrfs scrub cancel "$target"; then
                    printf 'cancelled running scrub on %s\n' "$target" >&2
                else
                    rc="$?"
                    printf 'failed to cancel scrub on %s (exit %s)\n' "$target" "$rc" >&2
                    printf 'probably no scrub was running\n' >&2
                fi

                # `btrfs balance cancel` doesn't save the current state, and
                # instead just cancels the entire operation.  `btrfs balance
                # pause`, however, does save the current state.
                if btrfs balance pause "$target"; then
                    printf 'paused running balance on %s\n' "$target" >&2
                else
                    rc="$?"
                    printf 'failed to pause balance on %s (exit %s)\n' "$target" "$rc" >&2
                    printf 'probably no balance was running\n' >&2
                fi
              '';
            };
          in
          "${script} %f";
      };
    };

    "btrfs-maintenance-resume-after-sleep@" = {
      description = "Resume btrfs scrub/balance interrupted by sleep on %f";
      before = [ "sleep.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStop = "${pkgs.systemd}/bin/systemctl start btrfs-maintenance-resume@%i";
      };
      unitConfig.StopWhenUnneeded = true;
    };
  };

  systemd.targets = {
    multi-user.wants = map (
      fs: "btrfs-maintenance-resume@${mylib.escapeSystemdPath fs}.service"
    ) scrubFileSystems;
    sleep.wants = map (
      fs: "btrfs-maintenance-resume-after-sleep@${mylib.escapeSystemdPath fs}.service"
    ) scrubFileSystems;
    timers.wants = map (fs: "btrfs-balance@${mylib.escapeSystemdPath fs}.timer") scrubFileSystems;
  };
}
