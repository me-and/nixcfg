{
  config,
  lib,
  mylib,
  pkgs,
  ...
}:
let
  cfg = config.programs.taskwarrior;

  syncConfigured = (cfg.config.taskd.server or "") != "";

  # Based on Home Manager's taskwarrior module.
  formatValue =
    value:
    if lib.isBool value then
      if value then "1" else "0"
    else if lib.isList value then
      lib.concatMapStringsSep "," formatValue value
    else
      toString value;

  v2 = lib.versionAtLeast cfg.package.version "2" && lib.versionOlder cfg.package.version "3";
  v3 = lib.versionAtLeast cfg.package.version "3" && lib.versionOlder cfg.package.version "4";

  defaultTaskArgs = {
    color = false;
    detection = false;
    expiry = false;
    gc = false;
    hooks = false;
    recurrence = false;
    "recurrence.trigger" = false;
    verbose = [ "footnote" ];
  };
  makeTaskCommandList =
    config: args:
    let
      config' = defaultTaskArgs // config;
      configArgs = lib.mapAttrsToList (n: v: "rc.${n}=${formatValue v}") config';
    in
    [ (lib.getExe cfg.package) ] ++ configArgs ++ args;
  makeSystemdTaskCommand =
    config: args: mylib.escapeSystemdExecArgs (makeTaskCommandList config args);
  makeShellTaskCommand = config: args: lib.escapeShellArgs (makeTaskCommandList config args);
in
{
  imports = [
    (lib.mkRenamedOptionModule
      [ "programs" "taskwarrior" "createRecurringTasks" ]
      [ "programs" "taskwarrior" "config" "recurrence" ]
    )
    (lib.mkRemovedOptionModule [
      "programs"
      "taskwarrior"
      "sync"
    ] "Instead, set programs.taskwarrior.config.taskd as required.")
    (lib.mkRemovedOptionModule [
      "programs"
      "taskwarrior"
      "onedriveBackup"
    ] "Instead, set programs.taskwarrior.backup as required.")
    (lib.mkRemovedOptionModule
      [
        "programs"
        "taskwarrior"
        "recurrence"
        "enableWithGc"
      ]
      ''
        This option never worked with Taskwarrior v2, and with v3 is unnecessary
        now I have an overlay that separates out generating recurring tasks from
        garbage collection.  Instead, set
        programs.taskwarrior.recurrence.systemdSchedule.
      ''
    )
    (lib.mkRemovedOptionModule
      [
        "programs"
        "taskwarrior"
        "recurrence"
        "enableAlways"
      ]
      ''
        I wasn't using this option and I didn't want to keep writing code to
        maintain support for it.
      ''
    )
  ];

  options.programs.taskwarrior = {
    autoSync = (lib.mkEnableOption "automatic periodic running of `task sync`") // {
      default = syncConfigured;
    };

    backup = {
      enable = lib.mkEnableOption "regularly backing up Taskwarrior data";
      destination = lib.mkOption {
        type = lib.types.str;
        default = "${config.xdg.userDirs.documents}/tasks/${config.home.hostName}.json.zst";
        description = "Destination path for the backup file.  Should probably end in .json.zst.";
      };
    };

    recurrence = {
      systemdSchedule.enable = lib.mkEnableOption "creating recurring Taskwarrior tasks using a Systemd timer";
      systemdSchedule.timerConfig = lib.mkOption {
        description = ''
          Configuration to set on the systemd timer unit used for triggering
          creating recurring Taskwarrior tasks.
        '';
        default = {
          OnActiveSec = "0s";
          OnUnitInactiveSec = "8h";
          RandomizedDelaySec = "8h";
          AccuracySec = "8h";
        };
      };
    };

    expiry = {
      systemdSchedule.enable = lib.mkEnableOption "regularly deleting expired tasks using a Systemd timer";
      systemdSchedule.timerConfig = lib.mkOption {
        description = ''
          Configuration to set on the systemd timer unit used for triggering
          creating recurring Taskwarrior tasks.
        '';
        default = {
          OnActiveSec = "0s";
          OnUnitInactiveSec = "10min";
          RandomizedDelaySec = "10min";
          AccuracySec = "10min";
        };
      };
    };

    checkProjects.enable = lib.mkEnableOption "regularly checking for Taskwarrior projects that no longer have any tasks";

    checkGitHubIssues.enable = lib.mkEnableOption "regularly cehcking for open GitHub issues/PRs that are missing Taskwarrior tasks";
  };

  config = {
    assertions = [
      {
        assertion = cfg.autoSync -> syncConfigured;
        message = ''
          programs.taskwarrior.autoSync requires
          programs.taskwarrior.config.taskd to be configured
        '';
      }
      {
        assertion = lib.versionAtLeast cfg.package.version "3" -> (!cfg.autoSync && !syncConfigured);
        message = ''
          Using taskwarrior 3 is not (yet) compatible with my personal
          programs.taskwarrior.autoSync config, and definitely won't work with
          `programs.taskwarrior.config.taskd.
        '';
      }
      {
        assertion = v2 || v3;
        message = ''
          Unexpected Taskwarrior package version ${cfg.package.version}.
        '';
      }
      {
        assertion = cfg.expiry.systemdSchedule.enable -> v3;
        message = ''
          Using Taskwarrior expiry schedules only makes sense with Taskwarrior
          v3.
        '';
      }
    ];

    programs.taskwarrior = {
      enable = true;
      # Not using taskwarrior3 until its performance is more tolerable for my use
      # case.
      package = pkgs.taskwarrior2;
      config = {
        hooks.location = "${config.xdg.configHome}/task/hooks";
        recurrence = false;
        "recurrence.limit" = 2;
        color = {
          recurring = null;
          tag.next = null;
          tagged = null;
          tag.inbox = "rgb115";
          tag.problems = "green";
          active = "magenta";
          due = null;
          "due.today" = "red";
          overdue = "bold red";
          scheduled = null;
          blocked = "on rgb100";
          blocking = "on rgb001";
          uda.priority.T = null;
          uda.priority.H = null;
          uda.priority.M = null;
          uda.priority.L = null;
          deleted = "inverse underline";
          completed = "inverse";
        };
        dateformat.info = "a d b Y H:N:S";
        uda = {
          recurAfterDue.type = "duration";
          recurAfterDue.label = "Rec. after due";

          recurAfterWait.type = "duration";
          recurAfterWait.label = "Rec. after wait";

          recurAfterModifications.type = "string";
          recurAfterModifications.label = "Rec. after changes";

          # Random delays to wait and due dates to avoid things bunching up too
          # badly.
          waitRandomDelay.type = "duration";
          dueRandomDelay.type = "duration";
          recurAfterWaitRandomDelay.type = "duration";
          recurAfterDueRandomDelay.type = "duration";

          # "Until" behaviour on recurring tasks
          recurTaskUntil.type = "duration";
          recurTaskUntil.label = "Child until";

          # Fields for handling recurAfter rounding.
          recurAfterWaitRoundDown.type = "string";
          recurAfterWaitRoundDown.label = "Wait round down";
          recurAfterDueRoundDown.type = "string";
          recurAfterDueRoundDown.label = "Due round down";

          # Record where tasks came from
          source.type = "string";
          source.label = "Source";

          hiddenTags.type = "string";
          hiddenTags.label = "Hidden tags";

          # Record problems.
          problems.label = "Problems";
          problems.type = "string";

          # Field for implementing the blocks: attribute, which is implemented
          # by my Asmodeus hook scripts.
          blocks.type = "string";

          # Metadata to link Taskwarrior tasks with GitHub issues and pull
          # requests.
          ghmeta.type = "string";
          ghmeta.label = "GitHub metadata";
        };

        report =
          let
            oldOrNewColumnConfig = {
              columns = [
                "id"
                "start.age"
                "entry.age"
                "modified.age"
                "depends.indicator"
                "status.short"
                "priority"
                "project"
                "tags"
                "recur.indicator"
                "wait.remaining"
                "scheduled.relative"
                "due.relative"
                "until.relative"
                "description.count"
                "urgency"
              ];
              labels = [
                "ID"
                "Active"
                "Age"
                "Mod"
                "D"
                "S"
                "P"
                "Proj"
                "Tag"
                "R"
                "Wait"
                "Sch"
                "Due"
                "Until"
                "Description"
                "Urg"
              ];
              filter = "status:pending or status:waiting";
              context = false;
            };
          in
          {
            next = {
              columns = [
                "id"
                "start.age"
                "entry.age"
                "depends"
                "priority"
                "project"
                "tags"
                "recur"
                "scheduled.countdown"
                "wait.remaining"
                "due.relative"
                "until.remaining"
                "description.count"
                "urgency"
              ];
              labels = [
                "ID"
                "Act"
                "Age"
                "Deps"
                "P"
                "Project"
                "Tag"
                "R"
                "S"
                "Wait"
                "Due"
                "Unt"
                "Description"
                "Urg"
              ];
              filter = "-COMPLETED -DELETED -PARENT ( ( -WAITING -waitingfor -BLOCKED ) or ( +OVERDUE hiddenTags.noword:overdueallowed ) or +inbox )";
            };

            waitingfor = {
              description = "Tasks where I'm waiting on others";
              filter = "( +waitingfor status:pending -BLOCKED -inbox ) or ( description.is:'Review waitingfor report' +READY )";
              columns = [
                "id"
                "project"
                "due.relative"
                "until.remaining"
                "description.count"
              ];
              labels = [
                "ID"
                "Proj"
                "Due"
                "Until"
                "Description"
              ];
              context = false;
              sort = [ "due+" ];
            };

            waitingfor-full = {
              description = "All tasks where I'm waiting on others";
              filter = "+waitingfor (status:pending or status:waiting)";
              columns = [
                "id"
                "start.age"
                "project"
                "tags"
                "depends"
                "wait.remaining"
                "due.relative"
                "until.remaining"
                "description"
              ];
              labels = [
                "ID"
                "Age"
                "Proj"
                "Tag"
                "Dep"
                "Wait"
                "Due"
                "Until"
                "Description"
              ];
              context = false;
              sort = [ "due+" ];
            };

            oldest = oldOrNewColumnConfig;
            newest = oldOrNewColumnConfig;
            byid = oldOrNewColumnConfig // {
              description = "By ID for ease of wrangling";
              sort = [ "id" ];
            };
            byproj = oldOrNewColumnConfig // {
              description = "By project for ease of wrangling";
              sort = [
                "project+/"
                "id+"
              ];
            };
            all.context = false;
            completed.context = false;

            # More useful "completed" report details, which shows less extraneous
            # detail and prioritises showing the most recently completed tasks.
            completed = {
              columns = [
                "id"
                "uuid.short"
                "end.age"
                "priority"
                "project"
                "tags"
                "due"
                "description"
              ];
              labels = [
                "ID"
                "UUID"
                "Done"
                "P"
                "Proj"
                "Tags"
                "Due"
                "Description"
              ];
              sort = [ "end-" ];
            };

            # Include waiting tasks in the built-in reports I use, as I don't
            # want those to be hidden.
            overdue.filter = "( status:pending or status:waiting ) +OVERDUE";
            recurring.filter = "( ( status:pending or status:waiting ) +CHILD ) or ( status:recurring +PARENT )";

            # Show full project names in the "all" report.
            all.columns = [
              "id"
              "status.short"
              "uuid.short"
              "start.age"
              "entry.age"
              "end.age"
              "depends.indicator"
              "priority"
              "project"
              "tags"
              "recur.indicator"
              "wait.relative"
              "scheduled.relative"
              "due.relative"
              "until.relative"
              "description"
            ];
          };

        # Default to a report that'll show blocked and waiting tasks.
        default.command = "oldest";

        # Make searches case insensitive.  I don't want to remember whether the
        # word I'm thinking of in a description is at the beginning of the
        # description or not.
        search.case.sensitive = false;

        # Don't show logs in task info -- it's not worth the screen space.
        journal.info = false;

        urgency = {
          # Use inherited urgency for blocked tasks: tasks have the highest
          # urgency of their own urgency or whatever they're blocking.  Do
          # reduce the priority slighty for things that are blocked, just to
          # make sure they don't overtake the blocking tasks.
          blocking.coefficient = 0.1;
          blocked.coefficient = 0;
          "inherit" = true;

          # Reduce the urgency of tasks that are waiting, to reduce the extent
          # to which they boost tasks that block them but which aren't waiting.
          waiting.coefficient = -4;

          # I don't care whether a task is associated with a project or not.
          project.coefficient = 0;
          tags.coefficient = 0;
          annotations.coefficient = 0;

          # Reduce the impact of due dates.  This value puts a task that's due
          # right now, with no other factors, as having an urgency of 6, i.e.
          # identical to if it were high priority.
          due.coefficient = 8.2;

          # If a task can only be done during daylight, bump the priority
          # slightly so I get to it when it's available.
          user.tag.daylight.coefficient = 1;

          # Bump the priority of things that make my living space more pleasant,
          # because that's currently A Problem.
          user.tag.ufyh.coefficient = 3.6;

          # I do care about age, I want older tasks to bubble up to the top of
          # my queue.
          age.coefficient = 1.8;

          # Make sure overdue tasks get a bump akin to the inbox tag without the
          # due date.
          user.tag.OVERDUE.coefficient = 14;

          # Try to keep fewer plates spinning at the same time: increase the coefficient for active tasks from the default of 4.0.
          active.coefficient = 4.8;
        };

        # Disable nagging: I don't want to be told if I'm not completing the
        # highest priority task, as I already know.
        nag = "";

        # Disable changing every instance of a recurring tasks.  It's rare that
        # I want that, and if I do, I'll do it explicitly.
        "recurrence.confirmation" = false;

        # Disable renumbering tasks on every filter/list command.  Make it a
        # manual step that can happen overnight instead.
        gc = false;

        # I have a big shell prompt, so allow multiple lines for it.
        reserved.lines = 3;

        context =
          let
            readFilter = s: "( ${s} ) or +inbox or ( +OVERDUE hiddenTags.noword:overdueallowed )";
          in
          {
            evening-weekend.read = readFilter "-business -southport -steeplechase -work -office";
            allotment.read = readFilter "-home -southport -steeplechase -enfield -work -office";
            day-off = {
              # Prioritise things that can only be done in business hours.
              read = readFilter "-southport -steeplechase -work -office";
              rc.urgency.user.tag.business.coefficient = 6;
            };
            work = {
              # Prioritise things that can only be done at work or in business
              # hours.
              read = readFilter "-southport -steeplechase -multivac -hex -allotment -nsfw -alex";
              rc.urgency.user.tag = {
                work.coefficient = 6;
                business.coefficient = 4;
              };
            };
            steeplechase = {
              # Prioritise things that can only be done on site, and filter out
              # things that aren't urgent and aren't PD related.
              read = readFilter "-home -southport -enfield -work -office -nsfw -audio -allotment ( +steeplechase or urgency>=6 or project.is:pd or project:pd. )";
              write = "+steeplechase";
              rc.urgency.user.tag.steeplechase.coefficient = 10;
              rc.urgency.user.project.pd.coefficient = 3.6;
            };
            southport = {
              # Prioritise things that can only be done in Southport.
              read = readFilter "-allotment -enfield -steeplechase -home -work -office";
              rc.urgency.user.tag.southport.coefficient = 20;
            };
            bike.read = readFilter "-home -southport -steeplechase -enfield -work -office -car -multivac -cornwall -phone -alex";
            bed.read = readFilter "-home -southport -steeplechase -enfield -daylight -work -office -pc -multivac -hex -audio -business -alex -car -cornwall -phone -surface";
            office = {
              # Prioritise things that can only be done in the office.
              read = readFilter "-southport -steeplechase -multivac -hex -allotment -nsfw -alex -home -car";
              rc.urgency.user.tag = {
                business.coefficient = 2;
                work.coefficient = 6;
                office.coefficient = 10;
              };
            };
          };

        urgency.user.tag = {
          # Default urgency coefficients for things that have context-specific
          # urgencies.  Without this configuration, the context-specific
          # urgencies don't seem to work.
          work.coefficient = 0;
          business.coefficient = 0;
          steeplechase.coefficient = 0;
          southport.coefficient = 0;
          office.coefficient = 0;

          # Tasks in the inbox should be right at the top to get sorted.
          inbox.coefficient = 20;

          # Tasks tagged later should be significantly less urgent than they
          # otherwise might.  Taskwarrior also has "wait:later", which could do
          # a similar job, except that seems to break Taskserver sync.
          later.coefficient = -10;
        };
        urgency.user.project = {
          # Default urgency coefficients for things that have context-specific
          # urgencies.  Without this configuration, the context-specific
          # urgencies don't seem to work.
          pd.coefficient = 0;
        };

        # Remove "special" from the set of verbose values, since I know what
        # "next" does and I don't use any of the other special tags.
        verbose = [
          "affected"
          "blank"
          "context"
          "edit"
          "header"
          "footnote"
          "label"
          "new-id"
          "project"
          "sync"
          "override"
          "recur"
        ];

        # Disable the built-in aliases by configuring them to be themselves.  If I
        # type "history" in a task description, I don't want it to be silently
        # rewritten to "history.monthly".
        alias = {
          burndown = "burndown";
          ghistory = "ghistory";
          history = "history";
          rm = "rm";
        };

        # Rejig priorities: I want L to mean "explicitly low", and to rescore
        # accordingly.
        uda.priority.values = [
          "T"
          "H"
          "M"
          ""
          "L"
        ];
        urgency.uda.priority = {
          T.coefficient = 15;
          H.coefficient = 6;
          M.coefficient = 1.8;
          L.coefficient = -1.8;
        };

        # Configure programs.taskwarrior.config.taskd.credentials in the private
        # config flake.  Not sure this is necessary, but I'd rather have it private
        # than not.
        taskd = {
          server = "taskwarrior.dinwoodie.org:50340";
          trust = "strict";
        };
      };
    };

    home.packages = with pkgs.mypkgs; [
      task-project-report
      taskwarrior-annotations
      taskwarrior-ghmeta-merge
      taskwarrior-ghmeta-web
      tmux-taskloop
    ];

    home.shellAliases = {
      ttl = "tmux-taskloop";
    };

    home.file =
      let
        makeHook =
          name:
          pkgs.runCommandLocal name { buildInputs = [ pkgs.mypkgs.pythonWithAsmodeus ]; } ''
            cp ${./hooks + "/${name}"} "$out"
            patchShebangs "$out"
          '';
      in
      lib.mapAttrs' (
        k: v: lib.attrsets.nameValuePair "${cfg.config.hooks.location}/${k}" { source = makeHook k; }
      ) (builtins.readDir ./hooks);

    systemd.user = {
      services = {
        "resolve-host-a@" = {
          Unit = {
            Description = "Check %I resolves";
            Wants = [
              "network.target"
              "network-online.target"
            ];
            After = [
              "network.target"
              "network-online.target"
            ];
          };
          Service = {
            Type = "oneshot";
            ExecStart = "${lib.getExe pkgs.mypkgs.wait-for-host} %I";
          };
        };

        # Ensure the only Taskwarrior configuration that isn't declarative is
        # the stuff that's supposed to be transient.
        taskwarrior-config-check = {
          Unit.Description = "Check for unexpected Taskwarrior config";
          Service = {
            Type = "oneshot";
            ExecStart = pkgs.mypkgs.writeCheckedShellScript {
              name = "check-taskwarrior-config.sh";
              runtimeInputs = [ pkgs.gnugrep ];
              text = ''
                if [[ -v TASKRC ]]; then
                    config_file="$TASKRC"
                elif [[ -e "$HOME"/.taskrc ]]; then
                    config_file="$HOME"/.taskrc
                elif [[ -v XDG_CONFIG_HOME ]]; then
                    config_file="$XDG_CONFIG_HOME"/task/taskrc
                else
                    config_file="$HOME"/.config/task/taskrc
                fi

                if grep -Ev -e '^include ' -e '^context=' -e '^news\.version=' "$config_file"; then
                    echo "Unexpected content in $config_file" >&2
                    exit 1
                else
                    rc="$?"
                    if (( rc == 1 )); then
                        # Expected return code if nothing was found, which is what we're
                        # hoping for.
                        exit 0
                    else
                        echo "Unexpected error from grep (exit $rc)" >&2
                        exit "$rc"
                    fi
                fi
              '';
            };

          };
          Install.WantedBy = [ "default.target" ];
        };

        taskwarrior-wait-for-stability = {
          Unit.Description = "Wait until Taskwarrior files haven't changed for a while";
          Service = {
            Type = "oneshot";
            ExecStart = mylib.escapeSystemdExecArgs (
              [
                (lib.getExe pkgs.mypkgs.mtimewait)
                "180"
              ]
              ++ lib.optional v2 "${config.xdg.dataHome}/task/undo.data"
              ++ lib.optional v3 "${config.xdg.dataHome}/task/taskchampion.sqlite3"
            );
          };
        };

        taskwarrior-gc = {
          Unit.Description = "Perform Taskwarrior garbage collection";
          Service = {
            Type = "oneshot";
            ExecStart = makeSystemdTaskCommand { gc = true; } [ "ids" ];
          };
        };

        taskwarrior-gc-stable = {
          Unit = {
            Description = "Perform Taskwarrior garbage collection once the task files are stable";
            Wants = [ "taskwarrior-wait-for-stability.service" ];
            After = [ "taskwarrior-wait-for-stability.service" ];
          };
          Service = {
            Type = "oneshot";
            ExecStart = config.systemd.user.services.taskwarrior-gc.Service.ExecStart;
          };
        };

        taskwarrior-sync = lib.mkIf syncConfigured {
          Unit =
            let
              domain = lib.head (lib.splitString ":" cfg.config.taskd.server);
            in
            {
              Description = "Sync Taskwarrior data";
              Wants = [
                "resolve-host-a@${domain}.service"
                "taskwarrior-wait-for-stability.service"
              ];
              After = [
                "resolve-host-a@${domain}.service"
                "taskwarrior-wait-for-stability.service"
                "sops-nix.service"
              ];
              Before = [
                "taskwarrior-gc.service"
                "taskwarrior-gc-stable.service"
              ];
            };
          Service = {
            Type = "oneshot";
            ExecStart = makeSystemdTaskCommand { } [ "sync" ];
          };
        };

        taskwarrior-backup = lib.mkIf cfg.backup.enable {
          Unit = {
            Description = "Backup Taskwarrior data";
            Wants = [ "taskwarrior-wait-for-stability.service" ];
            After = [ "taskwarrior-wait-for-stability.service" ];
          };
          Service = {
            Type = "oneshot";
            ExecStart = pkgs.mypkgs.writeCheckedShellScript {
              name = "taskwarrior-backup.sh";
              runtimeInputs = [
                cfg.package
                pkgs.jq.bin
                pkgs.zstd.bin
              ];
              text = ''
                ${lib.toShellVars { inherit (cfg.backup) destination; }}
                mkdir -p -- "$(dirname -- "$destination")"
                rm -f -- "$destination".tmp
                ${makeShellTaskCommand { } [ "export" ]} |
                    jq 'map(del(.urgency))' |
                    zstd -o "$destination".tmp
                mv -- "$destination.tmp" "$destination"
              '';
            };
          };
        };

        taskwarrior-create-recurring-tasks = lib.mkIf cfg.recurrence.systemdSchedule.enable {
          Unit = {
            Description = "Create recurring Taskwarrior tasks";
            Wants = lib.mkIf syncConfigured [ "taskwarrior-sync.service" ];
            After = lib.mkIf syncConfigured [ "taskwarrior-sync.service" ];
            OnSuccess = lib.mkIf syncConfigured [ "taskwarrior-sync.service" ];
          };
          Service.Type = "oneshot";
          Service.ExecStart = makeSystemdTaskCommand {
            hooks = true;
            recurrence = true;
            "recurrence.trigger" = true;
          } [ "ids" ];
        };

        taskwarrior-project-check = lib.mkIf cfg.checkProjects.enable {
          Unit = {
            Description = "Check Taskwarrior project state";
            Wants = lib.mkIf syncConfigured [ "taskwarrior-sync.service" ];
            After = lib.mkIf syncConfigured [ "taskwarrior-sync.service" ];
            OnSuccess = lib.mkIf syncConfigured [ "taskwarrior-sync.service" ];
          };
          Service.Type = "oneshot";
          Service.Environment = [ "PATH=${lib.makeBinPath [ cfg.package ]}" ];
          Service.ExecStart = mylib.escapeSystemdExecArgs [
            (lib.getExe pkgs.mypkgs.pythonWithAsmodeus)
            ./projects.py
          ];
        };

        taskwarrior-github-check = lib.mkIf cfg.checkGitHubIssues.enable {
          Unit = {
            Description = "Check GitHub issue and PR tracking in Taskwarrior";
            Wants = lib.mkIf syncConfigured [ "taskwarrior-sync.service" ];
            After = lib.mkIf syncConfigured [ "taskwarrior-sync.service" ];
            OnSuccess = lib.mkIf syncConfigured [ "taskwarrior-sync.service" ];
          };
          Service.Type = "oneshot";
          Service.Environment =
            let
              runtimeInputs = [
                config.programs.taskwarrior.package
                pkgs.privatepkgs.gh-report-issues
              ];
            in
            [ "PATH=${lib.makeBinPath runtimeInputs}" ];
          Service.ExecStart = mylib.escapeSystemdExecArgs [
            (lib.getExe pkgs.mypkgs.pythonWithAsmodeus)
            ./github_issues.py
          ];
        };

        taskwarrior-expire = lib.mkIf cfg.expiry.systemdSchedule.enable {
          Unit = {
            Description = "Delete expired Taskwarrior tasks";
            Wants = lib.mkIf syncConfigured [ "taskwarrior-sync.service" ];
            After = lib.mkIf syncConfigured [ "taskwarrior-sync.service" ];
            OnSuccess = lib.mkIf syncConfigured [ "taskwarrior-sync.service" ];
          };
          Service.Type = "oneshot";
          Service.ExecStart = makeSystemdTaskCommand { expiry = true; } [ "ids" ];
        };
      };

      timers = {
        taskwarrior-config-check = {
          Unit.Description = "Regular recheck for unexpected Taskwarrior config";
          Timer = {
            OnUnitInactiveSec = "12h";
            RandomizedDelaySec = "12h";
            AccuracySec = "12h";
          };
          Install.WantedBy = [ "timers.target" ];
        };

        # Use a timer to start taskwarrior-gc rather than just having it wanted
        # by default.target so that sd-switch doesn't restart it when
        # home-manager reloads.
        taskwarrior-gc = {
          Unit.Description = "Perform Taskwarrior garbage collection at start of day";
          Timer.OnStartupSec = "0s";
          Install.WantedBy = [ "timers.target" ];
        };

        taskwarrior-gc-stable = {
          Unit.Description = "Perform Taskwarrior garbage collection overnight";
          Timer = {
            OnCalendar = "02:00";
            AccuracySec = "4h";
          };
          Install.WantedBy = [ "timers.target" ];
        };

        # Use a timer to start taskwarrior-sync at start of day rather than
        # just having it wanted by default.target so that sd-switch doesn't
        # restart it when home-manager reloads.
        taskwarrior-sync-start-of-day = lib.mkIf syncConfigured {
          Unit.Description = "Sync Taskwarrior data at start of day";
          Timer.OnStartupSec = "0s";
          Timer.Unit = "taskwarrior-sync.service";
          Install.WantedBy = lib.mkIf cfg.autoSync [ "timers.target" ];
        };

        taskwarrior-sync = lib.mkIf syncConfigured {
          Unit.Description = "Sync Taskwarrior data periodically";
          Timer = {
            OnUnitInactiveSec = "15m";
            RandomizedDelaySec = "15m";
            AccuracySec = "15m";
          };
          Install.WantedBy = lib.mkIf cfg.autoSync [ "timers.target" ];
        };

        taskwarrior-backup = lib.mkIf cfg.backup.enable {
          Unit.Description = "Regular backup of Taskwarrior data";
          Timer = {
            OnCalendar = "hourly";
            AccuracySec = "1h";
            RandomizedOffsetSec = "1h";
          };
          Install.WantedBy = [ "timers.target" ];
        };

        taskwarrior-create-recurring-tasks = lib.mkIf cfg.recurrence.systemdSchedule.enable {
          Unit.Description = "Regularly create recurring Taskwarrior tasks";
          Install.WantedBy = [ "timers.target" ];
          Timer = cfg.recurrence.systemdSchedule.timerConfig;
        };

        taskwarrior-project-check = lib.mkIf cfg.checkProjects.enable {
          Unit.Description = "Check Taskwarrior project state daily";
          Install.WantedBy = [ "timers.target" ];
          Timer = {
            OnCalendar = "daily";
            AccuracySec = "6h";
            Persistent = true;
          };
        };

        taskwarrior-github-check = lib.mkIf cfg.checkGitHubIssues.enable {
          Unit.Description = "Regularly check GitHub issue and PR tracking in Taskwarrior";
          Install.WantedBy = [ "timers.target" ];
          Timer = {
            OnActiveSec = "0s";
            OnUnitActiveSec = "30min";
            AccuracySec = "1h";
            RandomizedDelaySec = "1h";
          };
        };

        taskwarrior-expire = lib.mkIf cfg.expiry.systemdSchedule.enable {
          Unit.Description = "Regularly delete expired Taskwarrior tasks";
          Install.WantedBy = [ "timers.target" ];
          Timer = cfg.expiry.systemdSchedule.timerConfig;
        };
      };
    };
  };
}
