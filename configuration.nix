{ config, lib, options, pkgs, ... }:

let
  unstable = import <nixos-unstable> { config = config.nixpkgs.config; };
in {
  imports = [ ./channels.nix <home-manager/nixos> ]
    ++ lib.optional (builtins.pathExists ./hardware-configuration.nix) ./hardware-configuration.nix
    ++ [ ./nixos-platform ./local-config.nix ]
  ;

  config = {
    warnings = lib.optional (options.networking.hostName.highestPrio >= 1000) "System hostname left at default.  Consider setting networking.hostName.";

    boot.loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };

    # Always want to be in the UK.
    time.timeZone = "Europe/London";
    i18n.defaultLocale = "en_GB.UTF-8";

    # Always want to be using UK Dvorak.
    services.xserver.xkb.layout = "gb";
    services.xserver.xkb.variant = "dvorak";
    console.useXkbConfig = true;

    # Set up printing.
    services.printing.enable = true;
    services.printing.drivers = [ (pkgs.cups-kyocera-3500-4500 or unstable.cups-kyocera-3500-4500) ];

    # Set up sound.
    sound.enable = true;
    hardware.pulseaudio.enable = true;

    # Always want Vim to be my editor.
    programs.vim.defaultEditor = true;
    programs.vim.package = pkgs.vim-full;

    # Always want a /mnt directory.
    system.activationScripts.mnt = "mkdir -m 700 -p /mnt";

    # Check the channel list is as expected.
    nix.checkChannels = true;
    nix.channels = {
      home-manager =
        "https://github.com/nix-community/home-manager/archive/release-24.05.tar.gz";
      nixos = "https://nixos.org/channels/nixos-24.05";
      nixos-unstable = "https://nixos.org/channels/nixos-unstable";
    };

    # Always want locate running.
    services.locate = {
      enable = true;
      package = pkgs.plocate;
      localuser = null;  # Needed to silence warning about running as root.
    };

    environment.systemPackages = with pkgs; [
      file
      home-manager
      mailutils
    ];

    # Enable system emails.
    services.postfix.enable = true;

    # If this isn't WSL, want OpenSSH for inbound connections, and mDNS for
    # both inbound and outbound connections.
    services.openssh.enable = true;
    services.avahi.enable = true;
    services.avahi.nssmdns4 = true;

    # Always want fixed users.
    users.mutableUsers = false;

    # For the system Git installation, gitMinimal is fine; I'll have the full
    # installation, probably on the tip, in Home Manager.
    programs.git.enable = true;
    programs.git.package = pkgs.gitMinimal;

    home-manager.useGlobalPkgs = true;

    # Set up my user account.
    users.users.adam = {
      isNormalUser = true;
      hashedPasswordFile = "/etc/nixos/passwords/adam";
      description = "Adam Dinwoodie";
      extraGroups = [ "wheel" ];
      linger = true;
    };

    # Enable nix-index, run it automatically, and replace command-not-found
    # with it.
    programs.nix-index.enable = true;
    programs.nix-index.enableBashIntegration = true;
    programs.command-not-found.enable = false;
    environment.variables.NIX_INDEX_DATABASE = "/var/cache/nix-index";
    systemd.services.nix-index = {
      script = "${pkgs.nix-index}/bin/nix-index";
      environment.NIX_INDEX_DATABASE = "/var/cache/nix-index";
      environment.NIX_PATH = lib.concatStringsSep ":" [
        "nixpkgs=/nix/var/nix/profiles/per-user/root/channels/nixos"
        "nixos-config=/etc/nixos/configuration.nix"
        "/nix/var/nix/profiles/per-user/root/channels"
      ];
    };
    systemd.timers.nix-index = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "Mon 18:00";
        AccuracySec = "24h";
        RandomizedDelaySec = "1h";
        Persistent = "true";
      };
    };

    # Clean the Nix config store regularly.  TODO integrate this properly with
    # nix.gc and nix.optimise.
    nix.gc = {
      automatic = true;
      dates = "weekly";
      randomizedDelaySec = "6h";
      options = "--delete-older-than 7d";
    };
    systemd.services.nix-gc = {
      onSuccess = [ "nix-optimise.service" ];
    };

    # Set up the Nix daemon to be able to access environment variables for
    # things like access to private GitHub repositories.
    systemd.services.nix-daemon = lib.optionalAttrs (builtins.pathExists ./nix-daemon-environment) {
      serviceConfig.EnvironmentFile = "/etc/nixos/nix-daemon-environment";
    };

    # Trust anyone in the wheel group
    nix.settings.trusted-users = [ "@wheel" ];
    nix.settings.sandbox = "relaxed";

    nixpkgs.config.allowUnfree = true;
  };
}
