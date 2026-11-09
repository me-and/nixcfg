final: prev:
let
  wrap =
    unwrapped:
    let
      script = final.mypkgs.writeCheckedShellApplication {
        name = "task";
        runtimeInputs = [ unwrapped ];
        text = builtins.readFile ./task.sh;
      };
    in
    final.symlinkJoin {
      name = "${unwrapped.name}-wrapped";
      paths = [
        script
        unwrapped
      ];
      inherit (unwrapped) version;
      passthru.tests = unwrapped.passthru.tests or { };
      meta.mainProgram = script.meta.mainProgram;
    };
in
{
  taskwarrior2-unwrapped = prev.taskwarrior2.overrideAttrs (prevAttrs: {
    patches = prevAttrs.patches or [ ] ++ [
      # https://github.com/GothenburgBitFactory/taskwarrior/issues/3894 Report
      # but don't prompt about repairing dependencies, because the repair will
      # never work.
      ./no-dep-repair.diff

      # Personal preference: include parent tasks when using `task count`.
      ./count-parents.diff

      # Personal preference: permit removing the due date from a recurring task
      # (but not the parent recurrence template).
      ./permit-undue-recurring-tasks.diff
    ];
  });

  taskwarrior3-unwrapped = prev.taskwarrior3.overrideAttrs (prevAttrs: {
    patches = prevAttrs.patches or [ ] ++ [
      # https://github.com/GothenburgBitFactory/taskwarrior/issues/3894 Report
      # but don't prompt about repairing dependencies, because the repair will
      # never work.
      ./no-dep-repair-tw3.diff

      # https://github.com/GothenburgBitFactory/taskwarrior/issues/4216
      # Add config options for creating recurring tasks and expiring tasks
      # separately from gc settings.
      ./0001-Add-independent-expiry-and-recurrence-triggers.patch

      # Personal preference: include parent tasks when using `task count`.
      ./count-parents-tw3.diff

      # Personal preference: permit removing the due date from a recurring task
      # (but not the parent recurrence template).
      ./permit-undue-recurring-tasks-tw3.diff
    ];

    # https://github.com/GothenburgBitFactory/taskchampion/issues/785
    cargoDeps = final.applyPatches {
      src = prevAttrs.cargoDeps;
      patchFlags = [
        "-p1"
        "-dsource-registry-0/taskchampion-3.1.0"
      ];
      patches = [ ./taskchampion-renumber-gaps.diff ];
    };
  });

  taskwarrior2 = wrap final.taskwarrior2-unwrapped;
  taskwarrior3 = wrap final.taskwarrior3-unwrapped;
}
