# If Nginx happens to be enabled, I'll want to use virtual hosts to serve on
# specific IP addresses, and not serve on anything else.
{
  config,
  lib,
  ...
}: let
  cfg = config.services.nginx;
in {
  # TODO set this up so the default virtual host is configured only if no other
  # virtual host has been explicitly configured as the default.  That'll
  # involve finding a way to look through all the defined virtual hosts and
  # working out whether any of them have the default attribute set to true,
  # without matching the virtualHost defined in the config in this file.
  options.services.nginx.virtualHostDefaultBlocker = lib.mkOption {
    description = ''
      Whether to set up a default Nginx virtual host that will just return an
      error for any and all requests that aren't made to an explicitly
      configured virtual host.
    '';
    type = lib.types.bool;
    default = true;
  };

  config = lib.mkIf cfg.virtualHostDefaultBlocker {
    services.nginx.virtualHosts.default = {
      default = true;
      # Special return code 444 causes Nginx to terminate the connection
      # without a response.
      locations."/".return = 444;
      rejectSSL = true;
    };
  };
}
