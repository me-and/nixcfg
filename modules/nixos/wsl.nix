{
  config,
  lib,
  pkgs,
  ...
}: let
  tryWslModule = builtins.tryEval <nixos-wsl/modules>;
  hasWslModule = tryWslModule.success;
  wslModulePath = tryWslModule.value;

  windowsUsername = builtins.readFile (
    pkgs.runCommandLocal "username" {__noChroot = true;}
    ''
      /mnt/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe -c '$env:UserName' |
          ${pkgs.coreutils}/bin/tr -d '\r\n' >$out
    ''
  );
in {
  imports = lib.optional hasWslModule wslModulePath;

  options.system.isWsl = lib.mkEnableOption "WSL configuration";

  # Avoid errors if the module isn't present.  Without this, with lib.mkIf in
  # the config section below, we get errors.  AIUI this is because using
  # lib.mkIf to gate the config section below still needs the config values to
  # be set up, as lib.mkIf does config merging and needs to evaluate the
  # contents of the block.  Using lib.optionalAttrs is no better, because it
  # doesn't do any evaluation of the inner block itself, and therefore there's
  # a recursion error because it the interpreter needs to evaluate the entire
  # block to work out if config.system.isWsl is set inside it.
  options.wsl = lib.optionalAttrs (! hasWslModule) {
    enable = lib.mkOption {type = lib.types.anything;};
    defaultUser = lib.mkOption {type = lib.types.anything;};
  };

  config = lib.mkIf config.system.isWsl {
    assertions = [
      {
        assertion = hasWslModule;
        message = ''
          Enabling WSL requires the WSL module to be installed.

          Try running

              sudo nix-channel --add https://github.com/nix-community/NixOS-WSL/archive/refs/heads/main.tar.gz nixos-wsl
              sudo nix-channel --update nixos-wsl
        '';
      }
    ];

    wsl.enable = true;
    wsl.defaultUser = windowsUsername;

    # Override config from the regular config file.
    boot.loader = lib.mkForce {
      systemd-boot.enable = false;
      efi.canTouchEfiVariables = false;
    };

    # Don't want mDNS services, as I can get them from Windows.
    services.avahi.enable = lib.mkForce false;

    # Don't want to connect over SSH; there's no need for that.
    services.openssh.enable = false;

    environment.systemPackages = with pkgs; [
      putty # For psusan
      wslu # For wslview
    ];

    # OS should look after the clock.  Hopefully.
    services.timesyncd.enable = false;

    nix.channels.nixos-wsl = "https://github.com/nix-community/NixOS-WSL/archive/refs/heads/main.tar.gz";
  };
}
