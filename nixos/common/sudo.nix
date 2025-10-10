{
  security.sudo.extraConfig = ''
    # Preserve environment variables for root and %wheel
    Defaults:root,%wheel env_keep+=VISUAL
    Defaults:root,%wheel env_keep+=EDITOR
    Defaults:root,%wheel env_keep+=SYSTEMD_EDITOR
    Defaults:root,%wheel env_keep+=SUDO_EDITOR
  '';
}
