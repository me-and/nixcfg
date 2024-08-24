{
  config,
  lib,
  ...
}:
lib.mkIf config.services.jellyfin.enable {
  # I want the Jellyfin service to be higher priority than standard user
  # services.
  services.jellyfin.niceness = -5;

  # I should be able to do stuff with the Jellyfin-managed files.
  users.users."${config.users.me}".extraGroups = [config.services.jellyfin.group];
}
