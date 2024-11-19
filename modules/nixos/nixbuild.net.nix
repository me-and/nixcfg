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
    enableBuildSystems = lib.mkOption {
      type = lib.types.listOf (lib.types.enum buildSystems);
      description = ''
        The systems for which to use nixbuild.net as a build machine
      '';
      default = [];
      example = buildSystems;
    };
    enableSubstituter = lib.mkEnableOption "using nixbuild.net as a substituter";
    substituterOrder = let
      defaultAfter = (lib.mkAfter []).priority;
      defaultBefore = (lib.mkBefore []).priority;
    in
      lib.mkOption {
        type = lib.types.nullOr lib.types.int;
        default = defaultAfter;
        example = defaultBefore;
        description = ''
          Order value to apply with `lib.mkOrder` to the substituter, to
          determine whether Nix prefers using nixbuild.net or any other
          substituter (normally cache.nixos.org) when multiple are available.

          Set to `null` to disable any ordering and leave it to the NixOS
          builder.  Set to ${builtins.toString defaultAfter} (the default) to
          list the nixbuild.net substituter after any unordered substituters.
          Set to ${builtins.toString defaultBefore} to list the nixbuild.net
          substituter before any unordered substituters.
        '';
      };
    sshKeyPath = lib.mkOption {
      type = lib.types.path;
      description = ''
        Path to the SSH private key to be used for connecting to the
        nixbuild.net servers.
      '';
      apply = builtins.toString;
    };

    enable = lib.mkOption {
      type = lib.types.nullOr lib.types.bool;
      default = null;
      description = ''
        Whether to enable using nixbuild.net as a builder.

        This option has been deprecated in favour of specifying the specific
        build systems that should be used, using
        nix.nixBuildDotNet.enableBuildSystems.
      '';
    };
  };

  config = let
    deprecationConfig = lib.mkIf (cfg.enable != null) {
      warnings = [
        ''
          You have set nix.nixBuildDotNet.enable.  This has been deprecated in favour of
          nix.nixBuildDotNet.enableBuildSystems.
        ''
      ];

      nix.nixBuildDotNet.enableBuildSystems = lib.mkIf cfg.enable buildSystems;
    };

    sharedConfig = lib.mkIf ((cfg.enableBuildSystems != []) || cfg.enableSubstituter) {
      programs.ssh.extraConfig = ''
        Host eu.nixbuild.net
            PubkeyAcceptedKeyTypes ssh-ed25519
            ServerAliveInterval 60
            IPQoS throughput
            IdentityFile ${cfg.sshKeyPath}
      '';
      programs.ssh.knownHosts = {
        nixbuild = {
          hostNames = ["eu.nixbuild.net"];
          publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPIQCZc54poJ8vqawd8TraNryQeJnvH1eLpIDgbiqymM";
        };
      };
    };

    builderConfig = lib.mkIf (cfg.enableBuildSystems != []) {
      nix = {
        # Ideally this would only be set for these specific builders rather
        # than changing the global default, but that doesn't seem to be
        # possible.
        settings.builders-use-substitutes = lib.mkDefault true;

        distributedBuilds = true;
        buildMachines = let
          buildMachine = system: {
            inherit system;
            hostName = "eu.nixbuild.net";
            maxJobs = 100;
            supportedFeatures = ["benchmark" "big-parallel"];
          };
        in
          map buildMachine cfg.enableBuildSystems;
      };
    };

    substituterConfig = lib.mkIf cfg.enableSubstituter {
      nix.settings = {
        substituters =
          if cfg.substituterOrder == null
          then ["ssh://eu.nixbuild.net"]
          else lib.mkOrder cfg.substituterOrder ["ssh://eu.nixbuild.net"];
        trusted-public-keys = ["nixbuild.net/3V9K4V-1:zLEau7IqIsmK/NP/pp8pUDJ+tQiD77AxRapkORQXpio="];
      };
    };
  in
    lib.mkMerge [deprecationConfig sharedConfig builderConfig substituterConfig];
}
