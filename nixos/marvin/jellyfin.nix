{
  services.jellyfin = {
    enable = true;
    virtualHost = {
      enable = true;
      fqdn = "jelly.dinwoodie.org";
    };
    niceness = -5;
  };
}
