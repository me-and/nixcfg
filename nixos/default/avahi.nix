{
  services.avahi = {
    enable = true;
    settings.publish = {
      disable-publishing = false;
      disable-user-service-publishing = false;

      publish-domain = true;
      publish-workstation = true;
      publish-hinfo = true;
      publish-addresses = true;
    };
  };
}
