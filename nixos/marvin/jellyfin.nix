{
  services.jellyfin = {
    enable = true;
    virtualHost = {
      enable = true;
      fqdn = "jelly.dinwoodie.org";
      forceSecureConnections = true;
      enableACME = true;
    };
  };
}
