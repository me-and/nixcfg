{
  config,
  lib,
  ...
}:
{
  virtualisation.podman.enable = true;

  # Rootless Podman requires subordinate UID/GID ranges.  These must be set
  # explicitly when users.mutableUsers = false.
  users.users.${config.users.me} = {
    subUidRanges = lib.mkDefault [
      {
        startUid = 100000;
        count = 65536;
      }
    ];
    subGidRanges = lib.mkDefault [
      {
        startGid = 100000;
        count = 65536;
      }
    ];
  };
}
