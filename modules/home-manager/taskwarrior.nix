# TODO Finish converting the config from the original taskrc file currently
# included as extraConfig.
# TODO Make the config much more modular, DRY, and readable
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

  taskshReviewConfig = {
    uda.reviewed = {
      type = "date";
      label = "Reviewed";
    };
    report._reviewed = {
      description = "Tasksh review report.  Adjust the filter to your needs.";
      columns = ["uuid"];
      sort = ["problems" "reviewed+" "modified+"];
      filter = "( reviewed.none: or reviewed.before:now-6days or problems.any: ) -COMPLETED -DELETED";
      context = false;
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

  config.programs.taskwarrior = {
    config = lib.mkMerge [
      {
        hooks.location = "${config.xdg.configHome}/task/hooks";
        recurrence = cfg.createRecurringTasks;
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
        };

        report = let
          oldOrNewColumnConfig = {
            columns = ["id" "start.age" "entry.age" "modified.age" "depends.indicator" "status.short" "priority" "project" "tags" "recur.indicator" "wait.remaining" "scheduled.relative" "due.relative" "until.relative" "description" "urgency"];
            labels = ["ID" "Active" "Age" "Mod" "D" "S" "P" "Proj" "Tag" "R" "Wait" "Sch" "Due" "Until" "Description" "Urg"];
          };
        in {
          next = {
            columns = ["id" "start.age" "entry.age" "depends" "priority" "project" "tags" "recur" "scheduled.countdown" "due.relative" "until.remaining" "description.count" "urgency"];
            labels = ["ID" "Act" "Age" "Deps" "P" "Project" "Tag" "R" "S" "Due" "Unt" "Description" "Urg"];
            filter = "-COMPLETED -DELETED -PARENT ( ( -WAITING -waitingfor -BLOCKED ) or ( +OVERDUE hiddenTags.noword:overdueallowed ) or +inbox )";
          };

          waitingfor = {
            description = "Tasks where I'm waiting on others";
            filter = "+waitingfor status:pending -BLOCKED";
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

          oldest =
            {
              context = false;
            }
            // oldOrNewColumnConfig;
          newest =
            {
              context = false;
            }
            // oldOrNewColumnConfig;
          all.context = false;
          completed.context = false;
        };

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
        };

        # I have a big shell prompt, so allow multiple lines for it.
        reserved.lines = 3;
      }

      taskdConfig
      taskshReviewConfig
      priorityConfig
    ];
    extraConfig = ''
      # Context: evening and weekend
      context.evening-weekend.read=( -business -southport -dadford -work ) or +inbox or ( +OVERDUE hiddenTags.noword:overdueallowed )

      # Context: allotment
      context.allotment.read=( -home -southport -dadford -enfield -work ) or +inbox or ( +OVERDUE hiddenTags.noword:overdueallowed )

      # Context: day off.  Prioritise things that can only be done in business hours.
      context.day-off.read=( -southport -dadford -work ) or +inbox or ( +OVERDUE hiddenTags.noword:overdueallowed )
      context.day-off.rc.urgency.user.tag.business.coefficient=6

      # Context: work.  Prioritise things that can only be done at work or in
      # business hours
      context.work.read=( -southport -dadford -multivac -allotment -nsfw -alex ) or +inbox or ( +OVERDUE hiddenTags.noword:overdueallowed )
      context.work.rc.urgency.user.tag.work.coefficient=6
      context.work.rc.urgency.user.tag.business.coefficient=4

      # Context: dadford.  Prioritise things that can only be done on site.
      context.dadford.read=( -home -southport -enfield -business -work -nsfw -audio ( +dadford or urgency>=6 or project.is:pd or project:pd. ) ) or +inbox or ( +OVERDUE hiddenTags.noword:overdueallowed )
      context.dadford.write=+dadford
      context.dadford.rc.urgency.user.tag.dadford.coefficient=10

      # Context: southport.  Prioritise things that can only be done there.
      context.southport.read=( -allotment -enfield -dadford -home -work ) or +inbox or ( +OVERDUE hiddenTags.noword:overdueallowed )
      context.southport.rc.urgency.user.tag.southport.coefficient=20

      # Context: exercise bike
      context.bike.read=( -home -southport -dadford -enfield -work -car -multivac -cornwall -phone ) or +inbox or ( +OVERDUE hiddenTags.noword:overdueallowed )

      # Context: bed.
      context.bed.read=( -home -southport -dadford -enfield -daylight -work -pc -multivac -audio -business -alex -car -cornwall -phone -surface ) or +inbox or ( +OVERDUE hiddenTags.noword:overdueallowed )

      # Context: office.
      context.office.read=( -southport -dadford -multivac -allotment -nsfw -alex -home -car ) or +inbox or ( +OVERDUE hiddenTags.noword:overdueallowed )
      context.office.rc.urgency.user.tag.business.coefficient=2
      context.office.rc.urgency.user.tag.work.coefficient=6
      context.office.rc.urgency.user.tag.office.coefficient=10

      # Default urgency coefficients for things that have context-specific urgencies,
      # otherwise the context-specific ones seem to not take effect.
      urgency.user.tag.work.coefficient=0
      urgency.user.tag.business.coefficient=0
      urgency.user.tag.dadford.coefficient=0
      urgency.user.tag.southport.coefficient=0
      urgency.user.tag.office.coefficient=0

      # Tasks in the inbox should be right at the top to get sorted, unless there is
      # something even more burningly urgent.
      urgency.user.tag.inbox.coefficient=20

      # Tasks tagged "later" should be significantly less urgent than they otherwise
      # might.  This is an alternative to using "wait:later" or similar, since
      # "wait:later" seems to break TaskServer sync :(
      urgency.user.tag.later.coefficient=-10

      # More useful "completed" report details, limited to only showing a sensible
      # number of most recently completed tasks.
      report.completed.columns=id,uuid.short,end.age,priority,project,tags,due,description
      report.completed.labels=ID,UUID,Done,P,Proj,Tags,Due,Description
      report.completed.filter=status:completed
      report.completed.sort=end-

      # Remove "special" from the set of verbose values, since I know what "next"
      # does and don't use any of the other tags.
      verbose=affected,blank,context,edit,header,footnote,label,new-id,project,sync,override,recur

      # Taskwarrior seems confused about whether tasks that are waiting should be
      # included in status:pending or not.  The default report definitions seem to
      # assume they will be, but the behaviour assumes they won't be.  Change the
      # report definitions to match actual behaviour.
      report.active.filter=status:pending +ACTIVE
      report.blocked.filter=status:pending +BLOCKED
      report.blocking.filter=status:pending +BLOCKING
      report.list.filter=status:pending
      report.long.filter=status:pending
      report.ls.filter=status:pending
      report.minimal.filter=status:pending or status:waiting
      report.newest.filter=status:pending or status:waiting
      report.oldest.filter=status:pending or status:waiting
      report.overdue.filter=(status:pending or status:waiting) and +OVERDUE
      report.recurring.filter=((status:pending or status:waiting) +CHILD) or (status:recurring +PARENT)
      report.timesheet.filter=((status:pending or status:waiting) start.after:now-4wks) or (status:completed end.after:now-4wks)
      report.unblocked.filter=status:pending -BLOCKED
      report.waiting.filter=status:waiting

      # Show full project names in the "all" report.
      report.all.columns=id,status.short,uuid.short,start.age,entry.age,end.age,depends.indicator,priority,project,tags,recur.indicator,wait.relative,scheduled.relative,due.relative,until.relative,description

      # Record problems
      uda.problems.label=Problems
      uda.problems.type=string

      # Set dependencies from the blocking tasks as well as the blocked tasks.  This
      # should always be empty at the point a task is written to file, but it needs
      # to be defined as a UDA so the field exists for hooks to use.
      uda.blocks.type=string

      # When creating recurring tasks, create two of them so I get at least a couple
      # of days for daily tasks.
      recurrence.limit=2

      # More readable date formats.
      dateformat.info=a d b Y H:N:S

      # Default to something that'll show blocked and waiting tasks, as that's
      # probably what I want if I'm using a filter without specifying a report.
      default.command=oldest

      # Search case insensitive.  I don't want to remember whether the word I'm
      # thinking of in a description is at the start of the description or not.
      search.case.sensitive=0

      # I don't care whether a task is associated with a project or not.
      urgency.project.coefficient=0
      urgency.tags.coefficient=0
      urgency.annotations.coefficient=0

      # Reduce the impact of due dates.  This value puts a task that's due now as
      # having an urgency of 6, the same as having a priority of H.
      urgency.due.coefficient=8.2

      # If a task can only be done during daylight, bump the priority slightly so I
      # get to it when it's available
      urgency.user.tag.daylight.coefficient=1

      # I do care about age; I want older tasks to bubble up to the top of my queue.
      urgency.age.coefficient=3

      # Don't tell me about not completing the highest priority task; I know!
      nag=

      # Don't ask if I want to change every instance of a recurring task.  The vast
      # majority of the time I don't, and if I do, I can ask for that.
      recurrence.confirmation=no

      # Don't renumber tasks on every filter/list command, and instead make
      # renumbering a manual step that can happen overnight or similar.
      gc=0
    '';
  };
}
