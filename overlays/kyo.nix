# https://github.com/NixOS/nixpkgs/pull/358536
final: prev: let
  thisFile = "${builtins.toString ./.}/kyo.nix";
  name = "cups-kyocera-3500-4500";
in {
  "${name}" =
    if prev ? "${name}"
    then
      final.lib.warn "Unnecessary use of mostStablePackage in ${thisFile}."
      prev."${name}"
    else
      final.lib.channels.mostStablePackage {
        inherit name;
        excludeOverlays = ["kyo.nix"];
        config = {
          allowUnfreePredicate = pkg: (final.lib.getName pkg) == name;
        };
      };
}
