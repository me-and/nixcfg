{
  lib,
  pkgs,
  ...
}: {
  home.packages = [pkgs.jq];

  home.file =
    # TODO Move these files into Home Manager more competently; this directory
    # was just a lift-and-shift from my Homeshick castle.
    #
    # Handle each file separately, rather than just linking the entire
    # directory, so that it's possible for other Home Manager config to add
    # files as well.
    lib.mapAttrs'
    (name: value:
      lib.nameValuePair ".jq/${name}" {source = ./jq + "/${name}";})
    (builtins.readDir ./jq);
}
