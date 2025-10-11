{
  config,
  lib,
  pkgs,
  ...
}:
{
  options.nix.nhgc.minimumFreeSpace = lib.mkOption {
    description = ''
      Minimum amount of disk space, in bytes, that the garbage collector should
      aim to ensure is available in the /nix/store partition.
    '';
    type = lib.types.ints.positive;
    example = "`1024 * 1024 * 1024 * 5`";
  };

  config = {
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
      lib.optional
        ((config.nix.settings.keep-outputs or false) && (config.nix.settings.keep-derivations or true))
        ''
          You have nix.settings.keep-outputs and nix.settings.keep-derivations.
          Nix Heuristic GC doesn't cope well with this setup, because of the
          likelihood of circular dependencies, so you may need to run regular Nix
          garbage collection tools as well.
        '';

    # Use Nix Heuristic Garbage Collection to actually collect garbage.
    systemd.services.nix-nhgc = {
      description = "Nix Heuristic Garbage Collection";
      before = [ "nix-optimise.service" ];
      serviceConfig.Type = "oneshot";
      path = [ pkgs.nix-heuristic-gc ];
      script = ''
        bytes_free="$(df -B1 --output=avail /nix/store | grep -v Avail)"
        bytes_to_free=$(( ${builtins.toString config.nix.nhgc.minimumFreeSpace} - bytes_free ))
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
