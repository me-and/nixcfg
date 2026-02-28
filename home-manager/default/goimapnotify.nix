# Based on the imapnotify module in home-manager, but using goimapnotify's
# current configuration interface.
#
# https://github.com/nix-community/home-manager/issues/8386
{
  config,
  lib,
  mylib,
  pkgs,
  ...
}:
let
  cfg = config.services.goimapnotify;
  accountCfgs = lib.filterAttrs (n: v: v.goimapnotify.enable) config.accounts.email.accounts;

  accountSubmodule =
    { config, lib, ... }:
    {
      options.goimapnotify = {
        enable = lib.mkEnableOption "goimapnotify" // {
          default = config.goimapnotify.boxes != { };
        };
        boxes = lib.mkOption {
          type = lib.types.attrsOf (lib.types.submodule boxSubmodule);
          description = "Configuration for individual mailboxes.";
          default = { };
        };
        wait = lib.mkOption {
          type = lib.types.ints.unsigned;
          default = 1;
          description = ''
            Number of seconds to wait between being notified of a new email and
            triggering the specified command.
          '';
        };
        idleRestart = lib.mkOption {
          type = with lib.types; nullOr ints.positive;
          default = null;
          description = ''
            Number of minutes between restarts of the IMAP IDLE command, which
            may be necessary for some IMAP servers.
          '';
        };

        accountConfig = lib.mkOption {
          description = ''
            The full configuration for this email account.

            Setting this will override all other configuration options for the account.
          '';
          default = {
            inherit (config.imap) host;
            port =
              if config.imap.port != null then
                config.imap.port
              else if config.imap.tls.enable then
                993
              else
                143;
            tls = config.imap.tls.enable;
            tlsOptions.starttls = config.imap.tls.useStartTls;
            username = config.userName;
            passwordCmd = lib.concatMapStringsSep " " lib.escapeShellArg config.passwordCommand;
            boxes = lib.mapAttrsToList (n: v: v.mailboxConfig) config.goimapnotify.boxes;
          }
          // lib.optionalAttrs (config.goimapnotify.wait != 1) {
            inherit (config.goimapnotify) wait;
          }
          // lib.optionalAttrs (config.goimapnotify.idleRestart != null) {
            idleLogoutTimeout = config.goimapnotify.idleRestart;
          };
        };
      };
    };

  notifyActionOption =
    scenario:
    lib.mkOption {
      type = with lib.types; nullOr (either str package);
      description = "Command to run ${scenario}.";
      default = null;
    };
  boxSubmodule =
    {
      name,
      config,
      lib,
      ...
    }:
    {
      options = {
        mailbox = lib.mkOption {
          type = lib.types.str;
          description = "The name of the mailbox/folder to synchronise";
          default = name;
        };

        onNewMail = notifyActionOption "when new mail arrives";
        onNewMailPost = notifyActionOption "after the onNewMail command";
        onChangedMail = notifyActionOption "when a flag changes on an email";
        onChangedMailPost = notifyActionOption "after the onChangedMail command";
        onDeletedMail = notifyActionOption "when mail has been deleted";
        onDeletedMailPost = notifyActionOption "after the onDeletedMail command";

        mailboxConfig = lib.mkOption {
          description = ''
            The full configuration for this mailbox.

            Setting this will override all the other configuration options for the mailbox.
          '';
          default = lib.filterAttrs (n: v: v != null) {
            inherit (config)
              mailbox
              onNewMail
              onNewMailPost
              onChangedMail
              onChangedMailPost
              onDeletedMail
              onDeletedMailPost
              ;
          };
        };
      };
    };
in
{
  options = {
    services.goimapnotify = {
      enable = lib.mkEnableOption "goimapnotify";
      package = lib.mkPackageOption pkgs "goimapnotify" { };
      logLevel = lib.mkOption {
        description = "goimapnotify log level";
        type = lib.types.enum [
          "error"
          "warn"
          "info"
          "debug"
        ];
        default = "info";
      };

      config = lib.mkOption {
        description = "The full configuration to pass to goimapnotify.";
        default = {
          configurations = lib.mapAttrsToList (n: v: v.goimapnotify.accountConfig) accountCfgs;
        };
        type = with lib.types; attrsOf anything;
      };

      configFile = lib.mkOption {
        description = "The configuration file to pass to goimapnotify.";
        type = lib.types.path;
        default = pkgs.writers.writeJSON "goimapnotify-config.json" cfg.config;
      };
    };

    accounts.email.accounts = lib.mkOption {
      type = with lib.types; attrsOf (submodule accountSubmodule);
    };
  };

  config = lib.mkIf cfg.enable {
    # Based on the goimapnotify service unit file in the upstream repository.
    systemd.user.services.goimapnotify = {
      Unit = {
        Description = "Execute scripts on IMAP mailbox changes (new/deleted/update messages) using IDLE, golang version.";
        StartLimitIntervalSec = "1d";
        StartLimitBurst = 5;
      };
      Install.WantedBy = [ "default.target" ];
      Service = {
        ExecStart = mylib.escapeSystemdExecArgs [
          (lib.getExe cfg.package)
          "-conf"
          cfg.configFile
          "-log-level"
          cfg.logLevel
        ];
        Restart = "always";
        RestartSec = 30;
      };
    };
  };
}
