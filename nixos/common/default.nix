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
in {
  imports =
    [
      <home-manager/nixos>
      ../../modules/nixos
      ../../modules/shared
      ./jellyfin.nix
      ./garbage.nix
      ./gnome.nix
      ./gui-common.nix
      ./mail.nix
      ./nginx.nix
      ./nix-index.nix
      ./plasma.nix
      ./root.nix
      ./systemd.nix
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
      usbutils
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

    # Set up the Nix daemon to be able to access environment variables for
    # things like access to private GitHub repositories.
    systemd.services.nix-daemon.serviceConfig.EnvironmentFile = "-/etc/nixos/secrets/nix-daemon-environment";

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
        environmentFile = "/etc/nixos/secrets/mythic-beasts";
      };
    };

    # Keep intermediate build stages around to speed up subsequent builds.
    nix.extraOptions = ''
      keep-outputs = true
      keep-derivations = true
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
