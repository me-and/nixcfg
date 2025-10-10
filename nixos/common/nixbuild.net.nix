{
  config,
  lib,
  ...
}: let
  cfg = config.nix.nixBuildDotNet;

  buildSystems = [
    "x86_64-linux"
    "i686-linux"
    "aarch64-linux"
    "armv7l-linux"
  ];
in {
  options.nix.nixBuildDotNet = {
    builds = {
      enable = lib.mkEnableOption "using nixbuild.net as a build system";
      systems = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        description = ''
          The systems for which to use nixbuild.net as a build machine.
        '';
        default = buildSystems;
        example = [(builtins.head buildSystems)];
      };
    };

    substituter = {
      enable = lib.mkEnableOption "using nixbuild.net as a substituter";
      priority = lib.mkOption {
        type = lib.types.nullOr lib.types.int;
        default = null;
        description = ''
          Priority with which to use the nixbuild.net substituter.  Set to
          `null` to leave unspecified.  Lower numbers are higher priorities,
          and the Nix default substituter priority is 0.
        '';
      };
    };

    sshKeyPath = lib.mkOption {
      type = lib.types.path;
      description = ''
        Path to the SSH private key to be used for connecting to the
        nixbuild.net servers.
      '';
      apply = builtins.toString;
    };
  };

  imports = [
    (
      lib.mkRenamedOptionModule
      ["nix" "nixBuildDotNet" "enable"]
      ["nix" "nixBuildDotNet" "builds" "enable"]
    )
    (
      lib.mkChangedOptionModule
      ["nix" "nixBuildDotNet" "enableBuildSystems"]
      ["nix" "nixBuildDotNet" "builds"]
      (
        config:
          if config.nix.nixBuildDotNet.enableBuildSystems == []
          then {
            enable = false;
          }
          else {
            enable = true;
            systems = config.nix.nixBuildDotNet.enableBuildSystems;
          }
      )
    )
    (
      lib.mkRenamedOptionModule
      ["nix" "nixBuildDotNet" "enableSubstituter"]
      ["nix" "nixBuildDotNet" "substituter" "enable"]
    )
    (
      lib.mkRemovedOptionModule
      ["nix" "nixBuildDotNet" "substituterOrder"]
      ''
        The previous configuration did not reliably affect the order with which
        Nix would use substituters.  That's what the priority argument is for,
        which can be set with nix.nixBuildDotNet.substituter.priority.
      ''
    )
  ];

  config = let
    sharedConfig = lib.mkIf (cfg.builds.enable || cfg.substituter.enable) {
      programs.ssh.extraConfig = ''
        Host eu.nixbuild.net
            PubkeyAcceptedKeyTypes ssh-ed25519
            ServerAliveInterval 60
            IPQoS throughput
      '';
      programs.ssh.knownHosts = {
        nixbuild = {
          hostNames = ["eu.nixbuild.net"];
          publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPIQCZc54poJ8vqawd8TraNryQeJnvH1eLpIDgbiqymM";
        };
      };
    };

    builderConfig = lib.mkIf cfg.builds.enable {
      nix = {
        # Ideally this would only be set for these specific builders rather
        # than changing the global default, but that doesn't seem to be
        # possible.
        settings.builders-use-substitutes = lib.mkDefault true;
        distributedBuilds = true;

        buildMachines = [
          {
            hostName = "eu.nixbuild.net";
            systems = cfg.builds.systems;
            supportedFeatures = ["benchmark" "big-parallel" "kvm" "nixos-test"];
            sshKey = cfg.sshKeyPath;
            maxJobs = 10000;
          }
        ];
      };
    };

    substituterConfig = let
      storeUrl =
        if cfg.substituter.priority == null
        then "ssh://eu.nixbuild.net?ssh-key=${cfg.sshKeyPath}"
        else "ssh://eu.nixbuild.net?ssh-key=${cfg.sshKeyPath}&priority=${toString cfg.substituter.priority}";
    in
      lib.mkIf cfg.substituter.enable {
        nix.settings = {
          substituters = [storeUrl];
          trusted-public-keys = ["nixbuild.net/3V9K4V-1:zLEau7IqIsmK/NP/pp8pUDJ+tQiD77AxRapkORQXpio="];
        };
      };
  in
    lib.mkMerge [sharedConfig builderConfig substituterConfig];
}
