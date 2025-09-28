# https://github.com/GothenburgBitFactory/taskwarrior/issues/3894
# Report but don't prompt about repairing dependencies, because the repair will
# never work.
final: prev: {
  taskwarrior2 = prev.taskwarrior2.overrideAttrs (prevAttrs: {
    patches = (prevAttrs.patches or []) ++ [./no-dep-repair.diff];
  });
}
