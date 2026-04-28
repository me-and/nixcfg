final: prev: {
  taskwarrior2-unwrapped = prev.taskwarrior2.overrideAttrs (prevAttrs: {
    patches = (prevAttrs.patches or [ ]) ++ [
      # https://github.com/GothenburgBitFactory/taskwarrior/issues/3894 Report
      # but don't prompt about repairing dependencies, because the repair will
      # never work.
      ./no-dep-repair.diff

      # Add patches that are just my personal preference: include parent tasks
      # when using `task count`, and permit removing the due date from
      # recurring tasks.
      ./count-parents.diff
      ./permit-undue-recurring-tasks.diff
    ];
  });

  taskwarrior2 =
    let
      script = final.mypkgs.writeCheckedShellApplication {
        name = "task";
        runtimeInputs = [ final.taskwarrior2-unwrapped ];
        text = builtins.readFile ./task.sh;
      };
    in
    final.symlinkJoin {
      name = "taskwarrior2-wrapped";
      paths = [
        script
        final.taskwarrior2-unwrapped
      ];
      meta.mainProgram = script.meta.mainProgram;
    };
}
