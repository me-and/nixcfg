{
  config,
  lib,
  options,
  pkgs,
  ...
}: let
  windowsUsername = builtins.readFile (
    pkgs.runCommandLocal "username" {__noChroot = true;}
    ''
      /mnt/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe -c '$env:UserName' |
          ${pkgs.coreutils}/bin/tr -d '\r\n' >$out
    ''
  );
in {
  # If the module is present *and* WSL configuration is enabled, then set up
  # some other bits I want only on WSL systems.  This needs to check options
  # for whether the wsl attribute is present; config.wsl.enable won't be
  # available to query if the WSL module hasn't been imported, and checking if
  # config has a wsl attribute at all doesn't work if Nix can't check inside
  # this config definition.
  config = lib.optionalAttrs (options ? wsl) (
    lib.mkIf config.wsl.enable {
      wsl.defaultUser = windowsUsername;

      # Don't want mDNS services, as I can get them from Windows.
      services.avahi.enable = lib.mkForce false;
      services.avahi.nssmdns4 = lib.mkForce false;

      # Don't want to connect over SSH; there's no need for that.
      services.openssh.enable = false;

      environment.systemPackages = with pkgs; [
        putty # For psusan
        wslu # For wslview
      ];

      # OS should look after the clock.  Hopefully.
      services.timesyncd.enable = false;

      nix.channels.nixos-wsl = "https://github.com/nix-community/NixOS-WSL/archive/refs/heads/main.tar.gz";
    }
  );
}
