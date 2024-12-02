{
  config,
  lib,
  ...
}: let
  cfg = config.programs.taskwarrior;

  taskdConfig = lib.mkIf cfg.sync.enable {
    taskd.server = "${cfg.sync.address}:${builtins.toString cfg.sync.port}";
    taskd.certificate = cfg.sync.certPath;
    taskd.key = cfg.sync.keyPath;
    taskd.credentials = cfg.sync.credentials;
    taskd.trust = cfg.sync.trust;
  };

  recurrenceConfig = {
    recurrence = cfg.createRecurringTasks;
  };
in {
  options.programs.taskwarrior = {
    createRecurringTasks = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Whether to enable creating recurring tasks on this system.

        If multiple systems are syncing to the same task server, only one of
        them should have this enabled to avoid duplicate recurring tasks being
        created.
      '';
    };

    sync = {
      enable = lib.mkEnableOption "syncing with a taskd server";
      address = lib.mkOption {
        description = "Address of the taskd server";
        example = "example.org";
        type = lib.types.str;
      };
      port = lib.mkOption {
        description = "Port of the taskd server";
        type = lib.types.ints.u16;
        default = 53589;
      };
      credentials = lib.mkOption {
        description = "User identification for syncing with the task server.";
        type = lib.types.str;
        example = "adam/adam/cebff340-bfcb-4f71-ad0a-45452484e123";
      };
      certPath = lib.mkOption {
        description = "Path to the certificate.";
        type = lib.types.path;
        apply = builtins.toString;
      };
      keyPath = lib.mkOption {
        description = "Path to the certificate key.";
        type = lib.types.path;
        apply = builtins.toString;
      };
      trust = lib.mkOption {
        description = "How much to trust the server.";
        type = lib.types.enum ["strict" "ignore hostname" "allow all"];
        default = "strict";
      };
    };
  };

  config.programs.taskwarrior.config = lib.mkMerge [
    taskdConfig
    recurrenceConfig
  ];
}
