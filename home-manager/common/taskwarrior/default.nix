{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.programs.taskwarrior;

  # TODO Finish converting the config from the original taskrc file currently
  # included as extraConfig.
  # TODO Make the config much more modular, DRY, and readable
  mainConfig = {
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
    };

    report = let
      oldOrNewColumnConfig = {
        columns = ["id" "start.age" "entry.age" "modified.age" "depends.indicator" "status.short" "priority" "project" "tags" "recur.indicator" "wait.remaining" "scheduled.relative" "due.relative" "until.relative" "description.count" "urgency"];
        labels = ["ID" "Active" "Age" "Mod" "D" "S" "P" "Proj" "Tag" "R" "Wait" "Sch" "Due" "Until" "Description" "Urg"];
        filter = "status:pending or status:waiting";
        context = false;
      };
    in {
      next = {
        columns = ["id" "start.age" "entry.age" "depends" "priority" "project" "tags" "recur" "scheduled.countdown" "due.relative" "until.remaining" "description.count" "urgency"];
        labels = ["ID" "Act" "Age" "Deps" "P" "Project" "Tag" "R" "S" "Due" "Unt" "Description" "Urg"];
        filter = "-COMPLETED -DELETED -PARENT ( ( -WAITING -waitingfor -BLOCKED ) or ( +OVERDUE hiddenTags.noword:overdueallowed ) or +inbox )";
      };

      waitingfor = {
        description = "Tasks where I'm waiting on others";
        filter = "+waitingfor status:pending -BLOCKED -inbox";
        columns = ["id" "project" "due.relative" "until.remaining" "description.count"];
        labels = ["ID" "Proj" "Due" "Until" "Description"];
        context = false;
        sort = ["due+"];
      };

      waitingfor-full = {
        description = "All tasks where I'm waiting on others";
        filter = "+waitingfor (status:pending or status:waiting)";
        columns = ["id" "start.age" "project" "tags" "depends" "wait.remaining" "due.relative" "until.remaining" "description"];
        labels = ["ID" "Age" "Proj" "Tag" "Dep" "Wait" "Due" "Until" "Description"];
        context = false;
        sort = ["due+"];
      };

      oldest = oldOrNewColumnConfig;
      newest = oldOrNewColumnConfig;
      byid =
        oldOrNewColumnConfig
        // {
          description = "By ID for ease of wrangling";
          sort = ["id"];
        };
      all.context = false;
      completed.context = false;

      # More useful "completed" report details, which shows less extraneous
      # detail and prioritises showing the most recently completed tasks.
      completed = {
        columns = ["id" "uuid.short" "end.age" "priority" "project" "tags" "due" "description"];
        labels = ["ID" "UUID" "Done" "P" "Proj" "Tags" "Due" "Description"];
        sort = ["end-"];
      };

      # Include waiting tasks in the built-in reports I use, as I don't
      # want those to be hidden.
      overdue.filter = "( status:pending or status:waiting ) +OVERDUE";
      recurring.filter = "( ( status:pending or status:waiting ) +CHILD ) or ( status:recurring +PARENT )";

      # Show full project names in the "all" report.
      all.columns = ["id" "status.short" "uuid.short" "start.age" "entry.age" "end.age" "depends.indicator" "priority" "project" "tags" "recur.indicator" "wait.relative" "scheduled.relative" "due.relative" "until.relative" "description"];
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

      # I do care about age, I want older tasks to bubble up to the top of
      # my queue.
      age.coefficient = 3;
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

    context = let
      readFilter = s: "( ${s} ) or +inbox or ( +OVERDUE hiddenTags.noword:overdueallowed )";
    in {
      evening-weekend.read = readFilter "-business -southport -dadford -work -office";
      allotment.read = readFilter "-home -southport -dadford -enfield -work -office";
      day-off = {
        # Prioritise things that can only be done in business hours.
        read = readFilter "-southport -dadford -work -office";
        rc.urgency.user.tag.business.coefficient = 6;
      };
      work = {
        # Prioritise things that can only be done at work or in business
        # hours.
        read = readFilter "-southport -dadford -multivac -hex -allotment -nsfw -alex";
        rc.urgency.user.tag = {
          work.coefficient = 6;
          business.coefficient = 4;
        };
      };
      dadford = {
        # Prioritise things that can only be done on site, and filter out
        # things that aren't urgent and aren't PD related.
        read = readFilter "-home -southport -enfield -work -office -nsfw -audio ( +dadford or urgency>=6 or project.is:pd or project:pd. )";
        write = "+dadford";
        rc.urgency.user.tag.dadford.coefficient = 10;
      };
      southport = {
        # Prioritise things that can only be done in Southport.
        read = readFilter "-allotment -enfield -dadford -home -work -office";
        rc.urgency.user.tag.southport.coefficient = 20;
      };
      bike.read = readFilter "-home -southport -dadford -enfield -work -office -car -multivac -cornwall -phone -alex";
      bed.read = readFilter "-home -southport -dadford -enfield -daylight -work -office -pc -multivac -hex -audio -business -alex -car -cornwall -phone -surface";
      office = {
        # Prioritise things that can only be done in the office.
        read = readFilter "-southport -dadford -multivac -hex -allotment -nsfw -alex -home -car";
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
      dadford.coefficient = 0;
      southport.coefficient = 0;
      office.coefficient = 0;

      # Tasks in the inbox should be right at the top to get sorted.
      inbox.coefficient = 20;

      # Tasks tagged later should be significantly less urgent than they
      # otherwise might.  Taskwarrior also has "wait:later", which could do
      # a similar job, except that seems to break Taskserver sync.
      later.coefficient = -10;
    };

    # Remove "special" from the set of verbose values, since I know what
    # "next" does and I don't use any of the other special tags.
    verbose = ["affected" "blank" "context" "edit" "header" "footnote" "label" "new-id" "project" "sync" "override" "recur"];
  };

  # Disable the built-in aliases by configuring them to be themselves.  If I
  # type "history" in a task description, I don't want it to be silently
  # rewritten to "history.monthly".
  aliasConfig = {
    alias = {
      burndown = "burndown";
      ghistory = "ghistory";
      history = "history";
      rm = "rm";
    };
  };

  # Rejig priorities: I want L to mean "explicitly low", and to rescore
  # accordingly.
  priorityConfig = {
    uda.priority.values = ["H" "M" "" "L"];
    urgency.uda.priority = {
      H.coefficient = 6;
      M.coefficient = 1.8;
      L.coefficient = -1.8;
    };
  };

  backupConfig = lib.mkIf cfg.onedriveBackup {
    # TODO
    warnings = [
      ''
        Need to sort out programs.taskwarrior.onedriveBackup to work with
        programs.rclone rather than just using the base rclone package.
      ''
    ];
    # assertions = [
    #   {
    #     assertion = config.programs.rclone.enable;
    #     message = ''
    #       cfg.programs.taskwarrior.onedriveBackup requires
    #       cfg.programs.rclone.enable.
    #     '';
    #   }
    # ];

    systemd.user = {
      services.taskwarrior-onedrive-backup = {
        Unit.Description = "Backup Taskwarrior data to OneDrive";
        Service = {
          Type = "oneshot";
          ExecStart = pkgs.mypkgs.writeCheckedShellScript {
            name = "taskwarrior-to-onedrive";
            runtimeInputs = [
              cfg.package
              config.programs.rclone.package
              pkgs.jq.bin
              pkgs.zstd.bin
            ];
            runtimeEnv.TZ = "UTC";
            text = ''
              printf -v filename '%(%F %H.%M.%S)T Z.json.zst'

              tmpdir="$(mktemp -d taskwarrior-to-onedrive.''$''$.XXXXX)"
              cleanup () {
                  rm -rf "$tmpdir"
              }
              trap cleanup EXIT

              output_file="$tmpdir"/"$filename"

              task export |
                  jq 'map(del(.urgency))' |
                  zstd -o "$output_file"

              rclone moveto "$output_file" onedrive:Taskwarrior/"$HOSTNAME"/"$filename"
            '';
          };
        };
      };

      timers.taskwarrior-onedrive-backup = {
        Unit.Description = "Daily backup Taskwarrior data to OneDrive";
        Timer = {
          OnCalendar = "01:00";
          AccuracySec = "1h";
          RandomizedOffsetSec = "6h";
          RandomizedDelaySec = "10min";
          Persistent = true;
        };
        Install.WantedBy = ["timers.target"];
      };
    };
  };

  # Configure programs.taskwarrior.config.taskd.credentials in the private
  # config flake.  Not sure this is necessary, but I'd rather have it private
  # than not.
  taskdConfig = {
    taskd = {
      server = "taskwarrior.dinwoodie.org:50340";
      certificate = "${config.xdg.configHome}/task/adam.cert.pem";
      key = "${config.xdg.configHome}/task/adam.key.pem";
      trust = "strict";
    };
  };
in {
  imports = [
    (lib.mkRenamedOptionModule ["programs" "taskwarrior" "createRecurringTasks"] ["programs" "taskwarrior" "config" "recurrence"])
    (lib.mkRemovedOptionModule ["programs" "taskwarrior" "sync"] "Instead, set programs.taskwarrior.config.taskd as required.")
  ];

  options.programs.taskwarrior = {
    autoSync = (lib.mkEnableOption "automatic periodic running of `task sync`") // {default = true;};

    onedriveBackup = lib.mkEnableOption "backup of Taskwarrior data to OneDrive";
  };

  config = lib.mkMerge [
    {
      programs.taskwarrior = {
        enable = true;
        # Not using taskwarrior3 until its performance is more tolerable for my use
        # case.
        package = pkgs.taskwarrior2;
        config = lib.mkMerge [
          mainConfig
          aliasConfig
          priorityConfig
          taskdConfig
        ];
      };

      home.packages = [pkgs.mypkgs.task-project-report];

      # TODO Patch these properly to use a Nix-appropriate shebang.
      home.file =
        lib.mapAttrs'
        (
          k: v:
            lib.attrsets.nameValuePair
            "${cfg.config.hooks.location}/${k}"
            {source = ./hooks + "/${k}";}
        )
        (builtins.readDir ./hooks);

      systemd.user = {
        services = {
          "resolve-host-a@" = {
            Unit = {
              Description = "Check %I resolves";
              Wants = ["network.target" "network-online.target"];
              After = ["network.target" "network-online.target"];
            };
            Service = {
              Type = "oneshot";
              ExecStart = "${pkgs.mypkgs.wait-for-host}/bin/wait-for-host %I";
            };
          };

          taskwarrior-wait-for-stability = {
            Unit.Description = "Wait until Taskwarrior files haven't changed for a while";
            Service = {
              Type = "oneshot";
              ExecStart = "${pkgs.mypkgs.mtimewait}/bin/mtimewait -f 180 ${config.xdg.dataHome}/task/undo.data";
            };
          };

          taskwarrior-gc = {
            Unit.Description = "Perform Taskwarrior garbage collection";
            Service = {
              Type = "oneshot";
              ExecStart = "${config.programs.taskwarrior.package}/bin/task rc.gc=1 rc.detection=0 rc.color=0 rc.recurrence=0 rc.hooks=0 ids";
            };
          };

          taskwarrior-gc-stable = {
            Unit = {
              Description = "Perform Taskwarrior garbage collection once the undo file is stable";
              Wants = ["taskwarrior-wait-for-stability.service"];
              After = ["taskwarrior-wait-for-stability.service"];
            };
            Service = config.systemd.user.services.taskwarrior-gc.Service;
          };

          taskwarrior-sync = {
            Unit = let
              domain = lib.head (lib.splitString ":" config.programs.taskwarrior.config.taskd.server);
            in {
              Description = "Sync Taskwarrior data";
              Wants = ["resolve-host-a@${domain}.service" "taskwarrior-wait-for-stability.service"];
              After = ["resolve-host-a@${domain}.service" "taskwarrior-wait-for-stability.service"];
              Before = ["taskwarrior-gc.service" "taskwarrior-gc-stable.service"];
            };
            Service = {
              Type = "oneshot";
              ExecStart = "${config.programs.taskwarrior.package}/bin/task rc.verbose=footnote rc.gc=0 rc.detection=0 rc.color=0 rc.hooks=0 rc.recurrence=0 sync";
            };
          };
        };

        timers = {
          # Use a timer to start taskwarrior-gc rather than just having it wanted
          # by default.target so that sd-switch doesn't restart it when
          # home-manager reloads.
          taskwarrior-gc = {
            Unit.Description = "Perform Taskwarrior garbage collection at start of day";
            Timer.OnStartupSec = "0s";
            Install.WantedBy = ["timers.target"];
          };

          taskwarrior-gc-stable = {
            Unit.Description = "Perform Taskwarrior garbage collection overnight";
            Timer = {
              OnCalendar = "02:00";
              AccuracySec = "4h";
            };
            Install.WantedBy = ["timers.target"];
          };

          # Use a timer to start taskwarrior-sync at start of day rather than
          # just having it wanted by default.target so that sd-switch doesn't
          # restart it when home-manager reloads.
          taskwarrior-sync-start-of-day = {
            Unit.Description = "Sync Taskwarrior data at start of day";
            Timer.OnStartupSec = "0s";
            Timer.Unit = "taskwarrior-sync.service";
            Install.WantedBy = lib.mkIf config.programs.taskwarrior.autoSync ["timers.target"];
          };

          taskwarrior-sync = {
            Unit.Description = "Sync Taskwarrior data periodically";
            Timer = {
              OnUnitInactiveSec = "15m";
              RandomizedDelaySec = "15m";
              AccuracySec = "15m";
            };
            Install.WantedBy = lib.mkIf config.programs.taskwarrior.autoSync ["timers.target"];
          };
        };
      };
    }
    backupConfig
  ];
}
