{
  config,
  lib,
  options,
  pkgs,
  ...
}: let
  defaultPrio = (lib.mkOptionDefault null).priority;
in {
  imports = [
    ../../modules/nixos
    ../../modules/shared
    ../../common
    ./avahi.nix
    ./emergency.nix
    ./jellyfin.nix
    ./garbage.nix
    ./gnome.nix
    ./gui-common.nix
    ./mail.nix
    ./nginx.nix
    ./nix-builder.nix
    ./nix-index.nix
    ./plasma.nix
    ./root.nix
    ./systemd.nix
    ./taskserver.nix
    ./user.nix
    ./vim.nix
  ];

  config = {
    warnings = lib.mkIf (options.networking.hostName.highestPrio >= defaultPrio) [
      "System hostname hasn't been set.  Consider setting networking.hostName."
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

    # Always want a /mnt directory.
    systemd.tmpfiles.rules = ["d /mnt"];

    # Always want screen.  Including this here looks like it also sets up some
    # PAM configuration, which is presumably relevant...
    programs.screen.enable = true;

    # Always want locate running.
    services.locate.enable = true;

    environment.systemPackages = with pkgs; [
      file
      home-manager
      nethogs
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
      experimental-features = ["nix-command" "flakes"];
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

    # Make sure all the systemd units for time wrangling that I care about get
    # included.
    systemd.additionalUpstreamSystemUnits = [
      # TODO including this causes problems because it's also included by the
      # default NixOS configuration, which can't cope with duplicates.  I want
      # to make it cope with duplicates so I can have the config here to be
      # able to rely on the file existing even if the reason for it existing
      # in NixOS disappears.
      # "time-sync.target"
      "time-set.target"
      "systemd-time-wait-sync.service"
    ];

    services.openssh.knownHosts = {
      "cygwin.com".publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKoejTnTCbXaIIMYfbX7t4tYUOQ2bTxZC3e/td3BageF";
      # https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/githubs-ssh-key-fingerprints
      "github.com".publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl";
      # https://docs.gitlab.com/user/gitlab_com/
      "gitlab.com".publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAfuCHKVTjquxvt6CM6tdG4SLp1Btn/nOeHHE5UOzRdf";
    };

    nix.nixBuildDotNet = {
      substituter = {
        enable = lib.mkDefault true;
        priority = 50;
      };
      sshKeyPath = "/etc/nixos/secrets/nixbuild-key";
    };

    services.nix-serve = {
      openFirewall = true;
      secretKeyFile = "/home/adam/store-secret";
    };
  };
}
