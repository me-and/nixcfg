{ config, lib, pkgs, ... }:
let
  tryWslModule = builtins.tryEval (builtins.findFile builtins.nixPath "nixos-wsl/modules");
  hasWslModule = tryWslModule.success;
  wslModulePath = tryWslModule.value;
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
    enable = lib.mkOption { type = lib.types.anything; };
    defaultUser = lib.mkOption { type = lib.types.anything; };
  };

  config = lib.mkIf config.system.isWsl {
    assertions = [{
      assertion = hasWslModule;
      message = ''
        Enabling WSL requires the WSL module to be installed.

        Try running

            sudo nix-channel --add https://github.com/nix-community/NixOS-WSL/archive/refs/heads/main.tar.gz nixos-wsl
            sudo nix-channel --update nixos-wsl
        '';
    }];

    wsl.enable = true;
    wsl.defaultUser = "adam";

    # Override config from the regular config file.
    boot.loader = lib.mkForce {
      systemd-boot.enable = false;
      efi.canTouchEfiVariables = false;
    };

    # Don't want printing, sound or mDNS services, as I can get them from
    # Windows.
    services.printing.enable = lib.mkForce false;
    sound.enable = lib.mkForce false;
    hardware.pulseaudio.enable = lib.mkForce false;
    services.avahi.enable = lib.mkForce false;
    services.avahi.nssmdns4 = lib.mkForce false;

    # Don't want to connect over SSH.
    services.openssh.enable = lib.mkForce false;

    environment.systemPackages = with pkgs; [
      putty  # For psusan
      wslu  # For wslview
    ];

    # TODO Work out why having linger enabled manages to _break_ commands like
    # `systemctl --user status`.  Probably related to
    # https://github.com/microsoft/WSL/issues/10205 although I don't quite
    # understand how.
    #
    # Ideally this would apply the configuration to all users that have
    # isNormalUser, but I can't work out how to do that without infinite
    # recursion :(
    users.users."${config.wsl.defaultUser}".linger = lib.mkForce false;

    # TODO Work out why WSL gives warnings about user IDs without this
    # configuration.
    users.users."${config.wsl.defaultUser}".uid = 1001;

    nix.channels.nixos-wsl =
      "https://github.com/nix-community/NixOS-WSL/archive/refs/heads/main.tar.gz";
  };
}
