{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.nix.nhgc;
in
{
  options.nix.nhgc = {
    minimumFreeSpaceBytes = lib.mkOption {
      description = ''
        Minimum amount of disk space, in bytes, that the garbage collector should
        aim to ensure is available in the /nix/store partition.
      '';
      type = lib.types.ints.unsigned;
      example = "`1024 * 1024 * 1024 * 5`";
      default = 0;
    };

    minimumFreeSpacePercent = lib.mkOption {
      description = ''
        Minimum amount of disk space, as a percentage of the total disk space,
        that the garbage collector should aim to ensure is available in the
        /nix/store partition.
      '';
      type = lib.types.numbers.between 0 100;
      example = 25;
      default = 0;
    };

    runFreeSpaceBytes = lib.mkOption {
      description = ''
        Amount of disk space, in bytes, that will trigger the garbage collector
        to run.
      '';
      type = lib.types.ints.unsigned;
      example = "`1024 * 1024 * 1024 * 3`";
      default = cfg.minimumFreeSpaceBytes;
    };

    runFreeSpacePercent = lib.mkOption {
      description = ''
        Amount of disk space, as a percentage of the total disk space, that
        will trigger the garbage collector to run.
      '';
      type = lib.types.numbers.between 0 100;
      example = 20;
      default = cfg.minimumFreeSpacePercent;
    };
  };

  imports = [
    (lib.mkRenamedOptionModule
      [ "nix" "nhgc" "minimumFreeSpace" ]
      [ "nix" "nhgc" "minimumFreeSpaceBytes" ]
    )
  ];

  config = {
    assertions = [
      {
        assertion = (cfg.minimumFreeSpaceBytes > 0) || (cfg.minimumFreeSpacePercent > 0);
        message = ''
          You need to set either `nix.nhgc.minimumFreeSpaceBytes` or
          `nix.nhgc.minimumFreeSpacePercent`.
        '';
      }
    ];

    # Run the standard garbage collector regularly, not to do actual Nix store
    # garbage collection, but to clean up old profiles and stale links.
    nix.gc = {
      options = "--max-freed 0 --delete-older-than 90d";
      automatic = true;
      dates = "weekly";
      persistent = true;
      randomizedDelaySec = "1h";
    };
    systemd.timers.nix-gc.timerConfig = {
      AccuracySec = "24h";
      RandomizedOffsetSec = "1w";
    };

    warnings =
      (lib.optional
        ((config.nix.settings.keep-outputs or false) && (config.nix.settings.keep-derivations or true))
        ''
          You have nix.settings.keep-outputs and nix.settings.keep-derivations.
          Nix Heuristic GC doesn't cope well with this setup, because of the
          likelihood of circular dependencies, so you may need to run regular Nix
          garbage collection tools as well.
        ''
      )
      ++ (lib.optional (cfg.runFreeSpacePercent > cfg.minimumFreeSpacePercent) ''
        nix.nhgc.runFreeSpacePercent is higher than
        nix.nhgc.minimumFreeSpacePercent.  This means Nix Heuristic GC will
        never free enough disk space that it doesn't need to run again next
        time.  You should normally configure runFreeSpacePercent to be the
        same or lower than minimumFreeSpacePercent.
      '')
      ++ (lib.optional (cfg.runFreeSpaceBytes > cfg.minimumFreeSpaceBytes) ''
        nix.nhgc.runFreeSpaceBytes is higher than
        nix.nhgc.minimumFreeSpaceBytes.  This means Nix Heuristic GC will
        never free enough disk space that it doesn't need to run again next
        time.  You should normally configure runFreeSpaceBytes to be the same
        or lower than minimumFreeSpaceBytes.
      '');

    # Use Nix Heuristic Garbage Collection to actually collect garbage.
    systemd.services.nix-nhgc = {
      description = "Nix Heuristic Garbage Collection";
      before = [ "nix-optimise.service" ];
      serviceConfig.Type = "oneshot";
      path = [
        pkgs.nix-heuristic-gc
        pkgs.bc
      ];
      script = ''
        minimum_free_bytes=${lib.escapeShellArg cfg.minimumFreeSpaceBytes}
        minimum_free_percent=${lib.escapeShellArg cfg.minimumFreeSpacePercent}

        run_free_bytes=${lib.escapeShellArg cfg.runFreeSpaceBytes}
        run_free_percent=${lib.escapeShellArg cfg.runFreeSpacePercent}

        df -B1 --output=size,avail /nix/store |
            tail -n+2 |
            while read -r bytes_total bytes_free; do
                if [[ "$run_free_percent" = 0 ]]; then
                    :
                else
                    run_free_bytes_percent="$(printf '%s * %s / 100\n' "$bytes_total" "$run_free_percent" | bc)"
                    if (( run_free_bytes_percent > run_free_bytes )); then
                        run_free_bytes="$run_free_bytes_percent"
                    fi
                fi

                if (( bytes_free >= run_free_bytes )); then
                    exit 0
                fi

                if [[ "$minimum_free_percent" = 0 ]]; then
                    :
                else
                    minimum_free_bytes_percent="$(printf '%s * %s / 100\n' "$bytes_total" "$minimum_free_percent" | bc)"
                    if (( minimum_free_bytes_percent > minimum_free_bytes )); then
                        minimum_free_bytes="$minimum_free_bytes_percent"
                    fi
                fi

                bytes_to_free=$(( minimum_free_bytes - bytes_free ))

                if (( bytes_to_free > 0 )); then
                    printf '%q\n' nix-heuristic-gc --penalize-substitutable "$bytes_to_free"
                fi
            done
      '';
    };
    systemd.timers.nix-nhgc = {
      timerConfig = {
        Persistent = true;
        OnCalendar = "weekly";
        AccuracySec = "24h";
        RandomizedDelaySec = "1h";
        RandomizedOffsetSec = "1w";
      };
      wantedBy = [ "timers.target" ];
    };

    # I expect to have lots of duplication in the store, so avoid that.
    nix.settings.auto-optimise-store = true;
  };
}
