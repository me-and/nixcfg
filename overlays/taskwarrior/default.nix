# https://github.com/GothenburgBitFactory/taskwarrior/issues/3894
# Report but don't prompt about repairing dependencies, because the repair will
# never work.
#
# Also add a patch that's just my personal preference: include parent tasks
# when using `task count`.
final: prev: {
  taskwarrior2 = prev.taskwarrior2.overrideAttrs (prevAttrs: {
    patches = (prevAttrs.patches or [ ]) ++ [
      ./no-dep-repair.diff
      ./count-parents.diff
    ];
  });
}
