{
  security.acme.defaults.email = "certbot@post.dinwoodie.org";
  services.nixBinaryCache.serverAliases = ["192.168.1.131"];

  home-manager.users.root.programs.git.userEmail = "adam@dinwoodie.org";

  # TODO The below looks like it should work, but it causes a deadlock, which
  # is apparetly characteristic of fusermount recursive problems, even though
  # the bind mount AIUI _should_ refer to the folder on disk rather than the
  # overlaid mount.
  #
  # systemd.mounts = [
  #   {
  #     what = "/usr/local/share/av/music";
  #     where = "/run/bind-usr-local-share-av-music";
  #     type = "none";
  #     options = "bind";
  #     mountConfig = {
  #       RuntimeDirectory = "bind-usr-local-share-av-music";
  #     };
  #   }
  # ];
  #
  # programs.rclone.mounts = [
  #   {
  #     what = ":hasher,remote=/,hashes=quickxor:/run/bind-usr-local-share-av-music";
  #     where = "/usr/local/share/av/music";
  #     needsNetwork = false;
  #     mountOwner = "jellyfin";
  #     mountGroup = "jellyfin";
  #     mountDirPerms = "2775";
  #     mountFilePerms = "0664";
  #     cacheMode = "writes";
  #     extraRcloneArgs = [
  #       "--allow-non-empty"
  #       "--vfs-fast-fingerprint"
  #     ];
  #     extraUnitConfig = {
  #       unitConfig.RequiresMountsFor = [
  #         "/run/bind-usr-local-share-av-music"
  #       ];
  #       serviceConfig.User = "root";
  #       serviceConfig.Group = "root";
  #     };
  #   }
  # ];
}
