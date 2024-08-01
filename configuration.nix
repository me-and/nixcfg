{
  config,
  lib,
  options,
  pkgs,
  ...
}: let
  defaultPriority = (lib.mkOptionDefault {}).priority;

  fileIfExtant = file: lib.optional (builtins.pathExists file) file;

  currentDir = builtins.toString ./.;
in {
  imports =
    [
      <home-manager/nixos>
      ./local-config.nix
      ./modules/nixos
      ./modules/shared
    ]
    # hardware-configuration.nix is expected to be missing on WSL.
    ++ fileIfExtant ./hardware-configuration.nix;

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
          assertion = !(builtins.pathExists ./passwords);
          message = "./passwords exists, and has been renamed ./secrets";
        }
      ];

    boot.tmp.useTmpfs = true;

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
    system.activationScripts.mnt = "mkdir -m 700 -p /mnt";

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
      mailutils
    ];

    # Enable system emails.
    services.postfix.enable = true;

    services.avahi.enable = true;
    services.avahi.nssmdns4 = true;

    # For the system Git installation, gitMinimal is fine; I'll have the full
    # installation, probably on the tip, in Home Manager.
    programs.git.enable = true;
    programs.git.package = pkgs.gitMinimal;

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
        "nixos-config=${currentDir}/configuration.nix"
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

    # Clean the Nix config store regularly.  TODO integrate this properly with
    # nix.gc and nix.optimise.
    nix.gc = {
      automatic = true;
      dates = "weekly";
      randomizedDelaySec = "6h";
      options = "--delete-older-than 7d";
    };
    systemd.services.nix-gc = {
      onSuccess = ["nix-optimise.service"];
      serviceConfig = {
        IOSchedulingClass = "idle";
        CPUSchedulingPriority = "idle";
      };
    };

    # Set up the Nix daemon to be able to access environment variables for
    # things like access to private GitHub repositories.
    systemd.services.nix-daemon.serviceConfig.EnvironmentFile = "-${currentDir}/secrets/nix-daemon-environment";

    nix.settings = {
      trusted-users = ["@wheel"];
      sandbox = "relaxed";
      experimental-features = ["nix-command"];
    };

    # Prioritize non-build work.
    nix.daemonIOSchedPriority = 7;
    nix.daemonCPUSchedPolicy = "batch";

    # Keep intermediate build stages around to speed up subsequent builds.
    nix.extraOptions = ''
      keep-outputs = true
      keep-derivations = true
    '';
  };
}
