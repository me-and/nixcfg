{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.nix.gc;
in
{
  disabledModules = [ "services/misc/nix-gc.nix" ];

  options.nix.gc = {
    enable = (lib.mkEnableOption "automatic garbage collection") // {
      default = true;
    };

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

          Set this to an amount lower than `nix.gc.target.freeBytes` to
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

          Set this to an amount lower than `nix.gc.target.freePercent` to
          ensure the garbage collector leaves plenty of free space and is less
          likely to need to perform garbage collection next time it is
          scheduled to check.
        '';
        type = lib.types.numbers.between 0 100;
        example = 20;
        default = cfg.target.freePercent;
      };
    };

    deleteOlderThan = lib.mkOption {
      description = ''
        The argument to pass to `nix-collect-garbage`'s `--delete-older-than`
        option to clean up old profiles.

        If set to `null`, old profiles will not be deleted.
      '';
      type = with lib.types; nullOr str;
      default = "90d";
      example = "7d";
    };
  };

  imports = [ (lib.mkRenamedOptionModule [ "nix" "nhgc" ] [ "nix" "gc" ]) ];

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = (cfg.target.freeBytes > 0) || (cfg.target.freePercent > 0);
        message = ''
          You need to set either `nix.gc.target.freeBytes` or
          `nix.gc.target.freePercent`.
        '';
      }
    ];

    warnings =
      (lib.optional (cfg.trigger.freePercent > cfg.target.freePercent) ''
        nix.gc.trigger.freePercent is higher than nix.hgc.target.freePercent.
        This means Nix garbage collection will never free enough disk space
        that it doesn't need to run again next time.  You should normally
        configure trigger.freePercent to be the same or lower than
        target.freePercent.
      '')
      ++ (lib.optional (cfg.trigger.freeBytes > cfg.target.freeBytes) ''
        nix.gc.trigger.freeBytes is higher than nix.gc.target.freeBytes.  This
        means Nix garbage collection will never free enough disk space that it
        doesn't need to run again next time.  You should normally configure
        trigger.freeBytes to be the same or lower than target.freeBytes.
      '');

    systemd.services.nix-gc = {
      description = "Nix Garbage Collection";
      before = [ "nix-optimise.service" ];
      serviceConfig.Type = "oneshot";
      path = [
        config.nix.package.out
        pkgs.bc
      ];
      script =
        let
          deleteOlderArguments = lib.optionals (cfg.deleteOlderThan != null) [
            "--delete-older-than"
            cfg.deleteOlderThan
          ];
        in
        ''
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

          printf "total bytes:  %'20d\n" "$bytes_total" >&2
          printf "bytes free:   %'20d\n" "$bytes_free" >&2
          printf "run if below: %'20d\n" "$run_free_bytes" >&2

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

          printf "target free:  %'20d\n" "$minimum_free_bytes"

          bytes_to_free=$(( minimum_free_bytes - bytes_free ))

          printf "to free:      %'20d\n" "$bytes_to_free"

          if (( bytes_to_free <= 0 )); then
              echo 'Nix garbage collection triggered despite having sufficient disk space' >&2
              exit 64  # EX_USAGE
          fi

          nix-collect-garbage --max-freed "$bytes_to_free" ${lib.escapeShellArgs deleteOlderArguments}

          # Check if sufficient space was freed.  Check against the "trigger"
          # rather than the "target", as it's fairly likely some disk space was
          # used while the garbage collection was running.
          update_free_space
          printf "bytes free:   %'20d\n" "$bytes_free" >&2
          if (( bytes_free < run_free_bytes )); then
              echo 'nix-collect-garbage failed to free sufficient disk space' >&2
              exit 75  # EX_TEMPFAIL
          fi
        '';
    };
    systemd.timers.nix-gc = {
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
