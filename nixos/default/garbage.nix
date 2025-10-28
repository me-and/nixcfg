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
    target = {
      freeBytes = lib.mkOption {
        description = ''
          How much disk space, in bytes, that the garbage collector will aim to
          ensure is available in the /nix/store partition.
        '';
        type = lib.types.ints.unsigned;
        example = "`1024 * 1024 * 1024 * 5`";
        default = 0;
      };

      freePercent = lib.mkOption {
        description = ''
          How much disk space, as a percentage of the total disk space, that
          the garbage collector should aim to ensure is available in the
          /nix/store partition.
        '';
        type = lib.types.numbers.between 0 100;
        example = 25;
        default = 0;
      };
    };

    trigger = {
      freeBytes = lib.mkOption {
        description = ''
          The amount of disk space, in bytes, that needs to be available to
          prevent the garbage collector running.

          Set this to an amount lower than `nix.nhgc.target.freeBytes` to
          ensure the garbage collector leaves plenty of free space and is less
          likely to need to perform garbage collection next time it is
          scheduled to check.
        '';
        type = lib.types.ints.unsigned;
        example = "`1024 * 1024 * 1024 * 3`";
        default = cfg.target.freeBytes;
      };

      freePercent = lib.mkOption {
        description = ''
          The amount of disk space, as a percentage of the total disk space,
          that needs to be available to prevent the garbage collector running.

          Set this to an amount lower than `nix.nhgc.target.freePercent` to
          ensure the garbage collector leaves plenty of free space and is less
          likely to need to perform garbage collection next time it is
          scheduled to check.
        '';
        type = lib.types.numbers.between 0 100;
        example = 20;
        default = cfg.target.freePercent;
      };
    };
  };

  imports =
    let
      mkNhgcRename =
        from: to:
        lib.mkRenamedOptionModule
          (
            [
              "nix"
              "nhgc"
            ]
            ++ from
          )
          (
            [
              "nix"
              "nhgc"
            ]
            ++ to
          );
    in
    [
      (mkNhgcRename [ "minimumFreeSpace" ] [ "target" "freeBytes" ])
      (mkNhgcRename [ "minimumFreeSpaceBytes" ] [ "target" "freeBytes" ])
      (mkNhgcRename [ "minimumFreeSpacePercent" ] [ "target" "freePercent" ])
      (mkNhgcRename [ "runFreeSpaceBytes" ] [ "trigger" "freeBytes" ])
      (mkNhgcRename [ "runFreeSpacePercent" ] [ "trigger" "freePercent" ])
    ];

  config = {
    assertions = [
      {
        assertion = (cfg.target.freeBytes > 0) || (cfg.target.freePercent > 0);
        message = ''
          You need to set either `nix.nhgc.target.freeBytes` or
          `nix.nhgc.target.freePercent`.
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
      ++ (lib.optional (cfg.trigger.freePercent > cfg.target.freePercent) ''
        nix.nhgc.trigger.freePercent is higher than
        nix.nhgc.target.freePercent.  This means Nix Heuristic GC will
        never free enough disk space that it doesn't need to run again next
        time.  You should normally configure trigger.freePercent to be the
        same or lower than target.freePercent.
      '')
      ++ (lib.optional (cfg.trigger.freeBytes > cfg.target.freeBytes) ''
        nix.nhgc.trigger.freeBytes is higher than nix.nhgc.target.freeBytes.
        This means Nix Heuristic GC will never free enough disk space that it
        doesn't need to run again next time.  You should normally configure
        trigger.freeBytes to be the same or lower than target.freeBytes.
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
        minimum_free_bytes=${lib.escapeShellArg cfg.target.freeBytes}
        minimum_free_percent=${lib.escapeShellArg cfg.target.freePercent}

        run_free_bytes=${lib.escapeShellArg cfg.trigger.freeBytes}
        run_free_percent=${lib.escapeShellArg cfg.trigger.freePercent}

        update_free_space () {
            local -i free_blocks total_blocks block_size

            free_blocks="$(stat --file-system --format=%f /nix/store)"
            total_blocks="$(stat --file-system --format=%b /nix/store)"
            block_size="$(stat --file-system --format=%S /nix/store)"

            bytes_free=$((free_blocks * block_size))
            bytes_total=$((total_blocks * block_size))
        }

        update_free_space

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
            nix-heuristic-gc --penalize-substitutable "$bytes_to_free"
        fi
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
