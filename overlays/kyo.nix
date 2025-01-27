# https://github.com/NixOS/nixpkgs/pull/358536
final: prev: let
  thisFile = "${builtins.toString ./.}/kyo.nix";
  name = "cups-kyocera-3500-4500";
in {
  "${name}" =
    final.lib.warnIf (final.lib.oldestSupportedReleaseIsAtLeast 2411)
    "Unnecessary use of mostStablePackage in ${thisFile}."
    (
      if prev ? name
      then prev."${name}"
      else
        final.lib.channels.mostStablePackage {
          inherit name;
          excludeOverlays = ["kyo.nix"];
          config = {
            allowUnfreePredicate = pkg: (final.lib.getName pkg) == name;
          };
        }
    );
}
