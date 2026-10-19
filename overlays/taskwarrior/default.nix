final: prev:
let
  wrapPackage = name: {
    "${name}-unwrapped" = (builtins.getAttr name prev).overrideAttrs (prevAttrs: {
      patches =
        (prevAttrs.patches or [ ])

        # https://github.com/GothenburgBitFactory/taskwarrior/issues/3894 Report
        # but don't prompt about repairing dependencies, because the repair will
        # never work.
        ++ (if (name == "taskwarrior2") then [ ./no-dep-repair.diff ] else [ ./no-dep-repair-tw3.diff ])

        # Personal preference: include parent tasks when using `task count`.
        ++ (if (name == "taskwarrior2") then [ ./count-parents.diff ] else [ ./count-parents-tw3.diff ])

        # Personal preference: permit removing the due date from a recurring
        # task (but not the parent recurrence template).
        ++ (
          if (name == "taskwarrior2") then
            [ ./permit-undue-recurring-tasks.diff ]
          else
            [ ./permit-undue-recurring-tasks-tw3.diff ]
        );
    });

    "${name}" =
      let
        script = final.mypkgs.writeCheckedShellApplication {
          name = "task";
          runtimeInputs = [ final."${name}-unwrapped" ];
          text = builtins.readFile ./task.sh;
        };
      in
      final.symlinkJoin {
        name = "${name}-wrapped";
        paths = [
          script
          final."${name}-unwrapped"
        ];
        inherit (final."${name}-unwrapped") version;
        meta.mainProgram = script.meta.mainProgram;
      };
  };
in
wrapPackage "taskwarrior2" // wrapPackage "taskwarrior3"
