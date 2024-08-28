{
  # I want a more informative log line.
  services.nginx.appendHttpConfig = ''
    log_format combined_with_host '$remote_addr - $remote_user [$time_local] $host:$server_port "$request" $status $body_bytes_sent "$http_referer" "$http_user_agent"';
    access_log /var/log/nginx/access.log combined_with_host;
  '';
}
