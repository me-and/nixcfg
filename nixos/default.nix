{ config, lib, pkgs, ... }:

let
  isHyperV = false;
  hostname = "multivac-nixos";

  hyperVResolution = "1920x1080";

  allInstalledPackages = builtins.concatLists (
    [ config.environment.systemPackages ]
    ++ (lib.mapAttrsToList (k: v: v.packages) config.users.users)
  );
  hasPackage = p: lib.any (x: x == p) allInstalledPackages;

  # https://discourse.nixos.org/t/installing-only-a-single-package-from-unstable/5598/4
  # Listed in rough stability order per
  # https://discourse.nixos.org/t/differences-between-nix-channels/13998
  altChannels = lib.forEach
    [
      { name = "small"; branch = "nixos-23.11-small"; }
      { name = "unstable"; branch = "nixos-unstable"; }
      { name = "unstable-small"; branch = "nixos-unstable-small"; }
      { name = "nixpkgs-unstable"; branch = "nixpkgs-unstable"; }
      { name = "nixpkgs-unstable-small"; branch = "nixpkgs-unstable-small"; }
      { name = "tip"; branch = "master"; }
    ]
    (v: v // rec {
      url = "https://github.com/NixOS/nixpkgs/archive/${v.branch}.tar.gz";
      tarball = fetchTarball url;
      pkgs = import tarball { config = config.nixpkgs.config; };
    });
    firstPackage =
      name:
      let
        allPackages =
          [ (pkgs."${name}" or null) ]
          ++ map (c: c.pkgs."${name}" or null) altChannels;
      in
      assert lib.any (p: p != null) allPackages;
      lib.findFirst (p: p != null) null allPackages;

in
{
  imports = [ ../common/channels.nix <home-manager/nixos> ]
    ++ lib.optional (builtins.pathExists ../hardware-configuration.nix) ../hardware-configuration.nix
    ++ [ ./wsl.nix ]
    ++ lib.optional isHyperV ./hyperv.nix
  ;

  config = {
    boot.loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };

    virtualisation.hypervGuest.videoMode = hyperVResolution;

    # Set network basics.
    networking.hostName = hostname;

    # Always want to be in the UK.
    time.timeZone = "Europe/London";
    i18n.defaultLocale = "en_GB.UTF-8";

    # Always want to be using UK Dvorak.
    services.xserver.layout = "gb";
    services.xserver.xkbVariant = "dvorak";
    console.useXkbConfig = true;

    # Set up printing.
    services.printing.enable = true;
    services.printing.drivers = [ (firstPackage "cups-kyocera-3500-4500") ];

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
        "https://github.com/nix-community/home-manager/archive/release-23.11.tar.gz";
      nixos = "https://nixos.org/channels/nixos-23.11";
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
    ];

    # If this isn't WSL, want OpenSSH for inbound connections, and mDNS for
    # both inbound and outbound connections.
    services.openssh.enable = true;
    services.avahi.enable = true;
    services.avahi.nssmdns = true;

    # Always want fixed users.
    users.mutableUsers = false;

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

    # Clean the Nix config store regularly.
    nix.gc = {
      automatic = true;
      dates = "weekly";
      randomizedDelaySec = "6h";
      options = "--delete-older-than 7d";
    };

    # Trust anyone in the wheel group
    nix.settings.trusted-users = [ "@wheel" ];
    nix.settings.sandbox = "relaxed";

    nixpkgs.config.allowUnfree = true;

    # This is the thing that comes with An Million Warnings about ever
    # changing...
    system.stateVersion = "23.11";
  };
}
