{
  services.nginx = {
    # I want a more informative log line.
    appendHttpConfig = ''
      log_format combined_with_host '$remote_addr - $remote_user [$time_local] $host:$server_port "$request" $status $body_bytes_sent "$http_referer" "$http_user_agent"';
      access_log /var/log/nginx/access.log combined_with_host;
    '';

    # Return an error for requests that aren't made to an explicitly configured
    # virtual host.
    virtualHosts.default = {
      default = true;
      # Special return code 444 causes Nginx to terminate the connection
      # without a response.
      locations."/".return = 444;
      rejectSSL = true;
    };
  };
}
