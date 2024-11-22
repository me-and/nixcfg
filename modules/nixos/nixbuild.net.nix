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
          builder.  Set to ${builtins.toString defaultAfter} (the default,
          equivalent to using `lib.mkAfter`) to list the nixbuild.net
          substituter after any unordered substituters.  Set to
          ${builtins.toString defaultBefore} (equivalent to using
          `lib.mkBefore`) to list the nixbuild.net substituter before any
          unordered substituters.
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
  };

  imports = [
    (
      lib.mkChangedOptionModule
      ["nix" "nixBuildDotNet" "enable"]
      ["nix" "nixBuildDotNet" "enableBuildSystems"]
      (
        config:
          if config.nix.nixBuildDotNet.enable
          then lib.mkDefault buildSystems
          else []
      )
    )
  ];

  config = let
    sharedConfig = lib.mkIf ((cfg.enableBuildSystems != []) || cfg.enableSubstituter) {
      # TODO find a way to get this config to work for the Nix build daemon
      # and/or root user *only* rather than also applying to user accounts that
      # shouldn't have access to this SSH key.
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
    lib.mkMerge [sharedConfig builderConfig substituterConfig];
}
