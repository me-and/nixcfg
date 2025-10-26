{
  config,
  lib,
  pkgs,
  ...
}:
let
  fsList = builtins.attrValues config.fileSystems;
  fsIsBtrfs = fs: fs.fsType == "btrfs";
  hasBtrfs = lib.any fsIsBtrfs fsList;
in
{
  environment.systemPackages = lib.optional hasBtrfs pkgs.btdu;
}
