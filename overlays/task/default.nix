# Create a taskwarrior package that's effectively the original taskwarrior
# package, but with the `task` binary wrapped with my Bash script to do some
# argument manipulation.  Doing it this way, rather than by patching the
# taskwarrior package directly to add the wrapper, means we can use the
# upstream build cache for the taskwarrior binaries and documentation and so
# forth.
final: prev: let
  taskWrapper =
    final.runCommandLocal
    "taskwrapper"
    {}
    ''
      mkdir -p $out/bin
      cp ${./task.sh} $out/bin/task
      patchShebangs $out/bin/task
      substituteInPlace $out/bin/task \
          --replace-fail 'command task' '${prev.taskwarrior}/bin/task' \
          --replace-warn 'exec task' 'exec ${prev.taskwarrior}/bin/task'
    '';

in {
#  taskwarrior = final.symlinkJoin {
#    name = "taskwarrior";
#    paths = [taskWrapper prev.taskwarrior];
#    postBuild = "echo hohoho";
#  };
}
