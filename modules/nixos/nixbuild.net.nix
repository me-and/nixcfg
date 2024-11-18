{
  config,
  lib,
  ...
}: let
  cfg = config.nix.nixBuildDotNet;

  buildMachine = system: {
    inherit system;
    hostName = "eu.nixbuild.net";
    maxJobs = 100;
    supportedFeatures = ["benchmark" "big-parallel"];
  };
  buildMachines = map buildMachine [
    "x86_64-linux"
    "i686-linux"
    "aarch64-linux"
    "armv7l-linux"
  ];
in {
  options.nix.nixBuildDotNet = {
    enable = lib.mkEnableOption "using nixbuild.net as a builder";
    enableSubstituter = lib.mkEnableOption "using nixbuild.net as a substituter";
    sshKeyPath = lib.mkOption {
      type = lib.types.path;
      description = ''
        Path to the SSH private key to be used for connecting to the
        nixbuild.net servers.
      '';
      apply = builtins.toString;
    };
  };

  config = let
    sharedConfig = lib.mkIf (cfg.enable || cfg.enableSubstituter) {
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

    builderConfig = lib.mkIf cfg.enable {
      nix = {
        distributedBuilds = true;
        buildMachines = let
          buildMachine = system: {
            inherit system;
            hostName = "eu.nixbuild.net";
            maxJobs = 100;
            supportedFeatures = ["benchmark" "big-parallel"];
          };
        in
          map buildMachine [
            "x86_64-linux"
            "i686-linux"
            "aarch64-linux"
            "arm7l-linux"
          ];
      };
    };

    substituterConfig = lib.mkIf cfg.enableSubstituter {
      nix.settings = {
        substituters = ["ssh://eu.nixbuild.net"];
        trusted-public-keys = ["nixbuild.net/3V9K4V-1:zLEau7IqIsmK/NP/pp8pUDJ+tQiD77AxRapkORQXpio="];
      };
    };
  in
    lib.mkMerge [sharedConfig builderConfig substituterConfig];
}
