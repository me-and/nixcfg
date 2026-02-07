{
  services.jellyfin = {
    enable = true;
    virtualHost = {
      enable = true;
      fqdn = "jelly.dinwoodie.org";
    };
    niceness = -5;
  };

  systemd.services.jellyfin = {
    after = [ "usr-local-share-av.mount" ];
    bindsTo = [ "usr-local-share-av.mount" ];
  };
}
