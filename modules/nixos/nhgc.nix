{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.nix.nhgc;
in {
  options.nix.nhgc = {
    enable = lib.mkEnableOption "periodically collecting garbage using the Nix Heuristic Garbage Collector";
    package = lib.mkPackageOption pkgs "Nix Heuristic Garbage Collector" {default = "nix-heuristic-gc";};
    optimiseAfter = lib.mkEnableOption "running nix-optimise after collecting garbage";
    minimumFreeSpace = lib.mkOption {
      description = ''
        Minimum amount of disk space, in bytes, that the garbage collector
        should aim to ensure is available in the /nix/store partition.
      '';
      type = lib.types.ints.positive;
      example = "`1024 * 1024 * 1024 * 5`";
    };
    options = lib.mkOption {
      description = "Arguments to pass to nix-heuristic-gc.";
      type = lib.types.listOf lib.types.str;
      example = ["--penalize-drvs"];
      default = [];
    };
    schedule = lib.mkOption {
      description = ''
        The schedule on which to run the garbage collection.  Must be in the
        calendar event format specified by systemd.time(7).

        Set to `null` to disable scheduled garbage collection.
      '';
      type = lib.types.nullOr lib.types.singleLineStr;
      default = null;
      example = "weekly";
    };
  };

  config = lib.mkIf cfg.enable {
    warnings =
      lib.optional
      ((config.nix.settings.keep-outputs or false)
        && (config.nix.settings.keep-derivations or true))
      ''
        You have nix.settings.keep-outputs and nix.settings.keep-derivations,
        as well as nix.nhgc.enable.  Nix Heuristic GC doesn't cope well with
        this setup, because of the likelihood of circular dependencies, so you
        may need to run regular Nix garbage collection tools as well.
      '';

    systemd.services.nix-nhgc = {
      description = "Nix Heuristic Garbage Collection";
      onSuccess = lib.mkIf cfg.optimiseAfter ["nix-optimise.service"];
      before = ["nix-optimise.service"];
      serviceConfig.Type = "oneshot";
      startAt = lib.optional (cfg.schedule != null) cfg.schedule;
      script = ''
        set -x

        df () {
            ${pkgs.coreutils}/bin/df "$@"
        }

        grep () {
            ${pkgs.gnugrep}/bin/grep "$@"
        }

        bytes_free="$(df -B1 --output=avail /nix/store | grep -v Avail)"
        bytes_to_free=$(( ${builtins.toString cfg.minimumFreeSpace} - bytes_free ))
        if (( bytes_to_free > 0 )); then
            ${cfg.package}/bin/nix-heuristic-gc ${lib.escapeShellArgs cfg.options} "$bytes_to_free"
        fi
      '';
    };
  };
}
