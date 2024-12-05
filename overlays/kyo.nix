# https://github.com/NixOS/nixpkgs/pull/358536
final: prev: let
  thisFile = "${builtins.toString ./.}/kyo.nix";
in {
  cups-kyocera-3500-4500 =
    if prev ? cups-kyocera-3500-4500
    then
      final.lib.warn "Unnecessary use of mostStablePackage in ${thisFile}."
      prev.cups-kyocera-3500-4500
    else
      final.lib.channels.mostStablePackage {
        name = "cups-kyocera-3500-4500";
        excludeOverlays = ["kyo.nix"];
        config = {
          allowUnfreePredicate = pkg: (final.lib.getName pkg) == "cups-kyocera-3500-4500";
        };
      };
}
