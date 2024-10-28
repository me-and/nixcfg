{
  config,
  lib,
  options,
  pkgs,
  ...
}: let
  defaultPriority = (lib.mkOptionDefault {}).priority;

  # Avoid using lib for this, so it can be safely used with imports.
  fileIfExtant = file:
    if builtins.pathExists file
    then [file]
    else [];

  configRootDir = builtins.toString ../..;
in {
  imports =
    [
      <home-manager/nixos>
      ../../modules/nixos
      ../../modules/shared
      ./jellyfin.nix
      ./garbage.nix
      ./mail.nix
      ./nginx.nix
      ./root.nix
      ./user.nix
    ]
    # I want to avoid using local-config.nix if I can, but sometimes using it
    # is the quickest and easiest option.
    ++ fileIfExtant ../../local-config.nix;

  config = {
    warnings = let
      # Emulate the nicer-in-my-opinion interface provided by the assertions
      # configuration.
      toWarningList = warning: lib.optional (!warning.assertion) warning.message;
      toWarningsList = builtins.concatMap toWarningList;
    in
      toWarningsList [
        {
          assertion = options.networking.hostName.highestPrio != defaultPriority;
          message = "System hostname left at default.  Consider setting networking.hostName";
        }
        {
          assertion = !(builtins.pathExists ../../passwords);
          message = "./passwords exists, and has been renamed ./secrets";
        }
      ];

    # Would rather use boot.tmp.useTmpfs, but that prevents some of my largest
    # Nix builds -- notably install images -- from being able to complete.
    boot.tmp.cleanOnBoot = true;

    # Always want to be in the UK.
    time.timeZone = "Europe/London";
    i18n.defaultLocale = "en_GB.UTF-8";

    # Always want to be using UK Dvorak.
    services.xserver.xkb.layout = "gb";
    services.xserver.xkb.variant = "dvorak";
    console.useXkbConfig = true;

    # Always want Vim to be my editor.
    programs.vim.defaultEditor = true;

    # Always want a /mnt directory.
    system.activationScripts.mnt = "mkdir -m 755 -p /mnt";

    # Always want screen.  Including this here looks like it also sets up some
    # PAM configuration, which is presumably relevant...
    programs.screen.enable = true;

    # Check the channel list is as expected.
    nix.checkChannels = true;
    nix.channels = {
      home-manager = "https://github.com/nix-community/home-manager/archive/release-24.05.tar.gz";
      nixos = "https://nixos.org/channels/nixos-24.05";
    };

    # Always want locate running.
    services.locate = {
      enable = true;
      package = pkgs.plocate;
      localuser = null; # Needed to silence warning about running as root.
    };

    environment.systemPackages = with pkgs; [
      file
      home-manager
    ];

    # Normally want SSHD.
    services.openssh.enable = lib.mkDefault true;

    services.avahi.enable = true;
    services.avahi.nssmdns4 = true;

    # For the system Git installation, gitMinimal is fine; I'll have the full
    # installation, probably on the tip, in Home Manager.
    programs.git.enable = true;
    programs.git.package = pkgs.gitMinimal.out;

    home-manager.useGlobalPkgs = true;

    # Make sure `apropos` and similar work.
    documentation.man.generateCaches = true;

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
        "nixos-config=${configRootDir}/configuration.nix"
        "/nix/var/nix/profiles/per-user/root/channels"
      ];
    };
    systemd.timers.nix-index = {
      wantedBy = ["timers.target"];
      timerConfig = {
        OnCalendar = "Mon 18:00";
        AccuracySec = "24h";
        RandomizedDelaySec = "1h";
        Persistent = "true";
      };
    };

    environment.gnome.excludePackages = with pkgs; [
      gnome-tour
      gnome.epiphany # Web browser
      gnome.geary # Email client
      gnome.gnome-contacts
      gnome.gnome-calendar
      gnome.gnome-maps
      gnome.gnome-music
      gnome.gnome-weather
      nixos-render-docs # NixOS manual
    ];

    # Don't need xterm if I'm using Gnome or Plasma, as they have their own,
    # better integrated, terminal emulators.
    services.xserver.excludePackages =
      lib.optional
      (config.services.desktopManager.plasma6.enable || config.services.xserver.desktopManager.gnome.enable)
      pkgs.xterm;

    # Set up the Nix daemon to be able to access environment variables for
    # things like access to private GitHub repositories.
    systemd.services.nix-daemon.serviceConfig.EnvironmentFile = "-${configRootDir}/secrets/nix-daemon-environment";

    nix.settings = {
      trusted-users = ["@wheel"];
      sandbox = "relaxed";
      experimental-features = ["nix-command"];
    };

    # Prioritize non-build work.
    nix.daemonIOSchedPriority = 7;
    nix.daemonCPUSchedPolicy = "batch";

    services.nixBinaryCache.serverAliases = [
      "127.0.0.1"
      "::1"
    ];

    # Set up basic ACME certificate configuration.
    security.acme = {
      acceptTerms = true;
      defaults = {
        dnsProvider = "mythicbeasts";
        environmentFile = "${configRootDir}/secrets/mythic-beasts";
      };
    };

    nix.extraOptions =
      # Keep intermediate build stages around to speed up subsequent builds.
      ''
        keep-outputs = true
        keep-derivations = true
      ''
      # I'm using local binary caches in some places, but if they're
      # inaccessible, I want the build to continue without them.
      #
      # See also https://github.com/NixOS/nix/issues/3514
      + ''
        connect-timeout = 3
        fallback = true
      '';

    # I've seen issues with time synchronisation that may or may not be related
    # to these units not being automatically included in the NixOS systemd
    # config.  Including them seems like it will do very little harm and might
    # help.
    boot.initrd.systemd.additionalUpstreamUnits = [
      "time-sync.target"
      "time-set.target"
    ];

    nixpkgs.config.allowUnfreePredicate = pkg:
      builtins.elem (lib.getName pkg) [
        "steam"
        "steam-original"
        "steam-run"
      ];
  };
}
