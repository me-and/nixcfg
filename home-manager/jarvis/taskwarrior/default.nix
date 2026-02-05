{ config, pkgs, ... }:
{
  accounts.email.accounts = {
    taskwarrior = {
      enable = true;
      goimapnotify.boxes.INBOX.onNewMail = "${pkgs.mypkgs.mailsync}/bin/mailsync -e taskwarrior -i";
    };
    main.goimapnotify.boxes.TaskWarrior.onNewMail = "${pkgs.mypkgs.mailsync}/bin/mailsync TaskWarrior";
  };

  systemd.user = {
    services = {
      taskwarrior-create-recurring-tasks = {
        Unit = {
          Description = "Create recurring Taskwarrior tasks";
          Wants = [ "taskwarrior-sync.service" ];
          After = [ "taskwarrior-sync.service" ];
          OnSuccess = [ "taskwarrior-sync.service" ];
        };
        Service.Type = "oneshot";
        Service.ExecStart = "${config.programs.taskwarrior.package}/bin/task rc.recurrence=true ids";
      };
      taskwarrior-check-active-tasks = {
        Unit = {
          Description = "Check for Taskwarrior tasks that have been active too long";
          Wants = [ "taskwarrior-sync.service" ];
          After = [ "taskwarrior-sync.service" ];
          OnSuccess = [ "taskwarrior-sync.service" ];
        };
        Service.Type = "oneshot";
        Service.ExecStart = pkgs.mypkgs.writeCheckedShellScript {
          name = "flag-stale-active-tasks.sh";
          runtimeInputs = [ config.programs.taskwarrior.package ];
          text = ''
            task_quick_quiet () {
                task rc.color=0 rc.detection=0 rc.gc=0 rc.hooks=0 rc.recurrence=0 rc.verbose=0 "$@"
            }

            filter=(+ACTIVE -COMPLETED -DELETED modified.before:now-28d)

            declare -i stale_active_tasks
            stale_active_tasks="$(task_quick_quiet "''${filter[@]}" count)"
            if (( stale_active_tasks > 0 )); then
                task_quick_quiet rc.bulk=0 "''${filter[@]}" modify +inbox
            fi
          '';
        };
      };

      taskwarrior-by-email = {
        Unit.Description = "Create Taskwarrior tasks sent by email";
        Unit.OnSuccess = [ "taskwarrior-sync.service" ];
        Service = {
          Type = "oneshot";
          Environment = [
            "MAILDIR_PATH=${config.accounts.email.accounts.taskwarrior.maildir.absPath}/INBOX"
          ];
          ExecStart =
            pkgs.runCommand "taskwarrior_email_inbox.py" { buildInputs = [ pkgs.mypkgs.pythonWithAsmodeus ]; }
              ''
                cp ${./taskwarrior_email_inbox.py} "$out"
                chmod +x "$out"
                patchShebangs "$out"
              '';
          ExecStartPost = "${pkgs.mypkgs.mailsync}/bin/mailsync -e taskwarrior -i";
        };
      };

      taskwarrior-main-emails = {
        Unit.Description = "Create Taskwarrior tasks from my emails to my main account";
        Unit.OnSuccess = [ "taskwarrior-sync.service" ];
        Service = {
          Type = "oneshot";
          # ExecStart defined in the private flake.
          ExecStartPost = "${pkgs.mypkgs.mailsync}/bin/mailsync TaskWarrior";
        };
      };
    };

    timers = {
      taskwarrior-create-recurring-tasks = {
        Unit.Description = "Regularly create recurring Taskwarrior tasks";
        Install.WantedBy = [ "timers.target" ];
        Timer = {
          OnActiveSec = "0s";
          OnUnitInactiveSec = "8h";
          RandomizedDelaySec = "8h";
          AccuracySec = "8h";
        };
      };
      taskwarrior-check-active-tasks = {
        Unit.Description = "Regularly check for tasks that have been active too long";
        Install.WantedBy = [ "timers.target" ];
        Timer = {
          OnActiveSec = "0s";
          OnUnitInactiveSec = "24h";
          RandomizedDelaySec = "24h";
          AccuracySec = "24h";
        };
      };
    };

    paths = {
      taskwarrior-by-email = {
        Unit.Description = "Create Taskwarrior tasks sent by email";
        Install.WantedBy = [ "paths.target" ];
        Path.DirectoryNotEmpty =
          let
            inbox = config.accounts.email.accounts.taskwarrior.maildir.absPath + "/INBOX";
          in
          [
            "${inbox}/new"
            "${inbox}/cur"
          ];
      };

      taskwarrior-main-emails = {
        Unit.Description = "Create Taskwarrior tasks from emails to my main account";
        Install.WantedBy = [ "paths.target" ];
        Path.DirectoryNotEmpty =
          let
            folder = config.accounts.email.accounts.main.maildir.absPath + "/TaskWarrior";
          in
          [
            "${folder}/new"
            "${folder}/cur"
          ];
      };
    };
  };
}
