# https://github.com/GothenburgBitFactory/taskwarrior/issues/3894
# Report but don't prompt about repairing dependencies, because the repair will
# never work.
#
# Also add patches that are just my personal preference: include parent tasks
# when using `task count`, and permit removing the due date from recurring
# tasks.
final: prev: {
  taskwarrior2 = prev.taskwarrior2.overrideAttrs (prevAttrs: {
    patches = (prevAttrs.patches or [ ]) ++ [
      ./no-dep-repair.diff
      ./count-parents.diff
      ./permit-undue-recurring-tasks.diff
    ];
  });
}
