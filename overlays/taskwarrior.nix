# Make sure taskwarrior2 points to taskwarrior if it isn't already defined.
final: prev: let
  lib = final.lib;
  thisFile = (builtins.toString ./.) + "/taskwarrior.nix";
  warning =
    lib.warnIf (lib.oldestSupportedReleaseIsAtLeast 2411)
    ''
      Overlay in ${thisFile} is unnecessary now that NixOS 24.05 is unsupported.
    '';
in {
  taskwarrior2 = warning (prev.taskwarrior2 or prev.taskwarrior);
}
