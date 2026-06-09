{ config, lib, ... }:
{
  options.nix = {
    githubTokenFromSops =
      lib.mkEnableOption "getting the GitHub authentication token for Nix from SOPS"
      // {
        default = true;
      };
    signBuilds = lib.mkEnableOption "automatically signing local builds using the key from SOPS";
  };

  config = lib.mkMerge [
    (lib.mkIf config.nix.githubTokenFromSops {
      sops = {
        secrets.github-token = { };
        templates.nix-daemon-environment.content = ''
          NIX_GITHUB_PRIVATE_USERNAME=.
          NIX_GITHUB_PRIVATE_PASSWORD=${config.sops.placeholder.github-token}
        '';
        templates.auth-tokens.content = ''
          access-tokens = github.com=${config.sops.placeholder.github-token}
        '';
      };

      systemd.services.nix-daemon.serviceConfig.EnvironmentFile =
        config.sops.templates.nix-daemon-environment.path;
      nix.extraOptions = ''
        !include ${config.sops.templates.auth-tokens.path}
      '';
    })

    (lib.mkIf config.nix.signBuilds {
      sops = {
        # Use templates to provide a degree of redirection, otherwise the
        # attempt to access sops.secrets.nix-cache-key.path will fail due to
        # infinite recursion in Nix when setting sops.secrets.nix-cache-key at
        # the same time.
        secrets.nix-cache-key = { };
        templates.nix-cache-key.content = config.sops.placeholder.nix-cache-key;
      };
      nix.settings.secret-key-files = config.sops.templates.nix-cache-key.path;
    })

    {
      nix.settings = {
        trusted-users = [ "@wheel" ];
        sandbox = "relaxed";
        experimental-features = [
          "nix-command"
          "flakes"
        ];
      };

      # Prioritize non-build work.
      nix.daemonIOSchedPriority = 7;
      nix.daemonCPUSchedPolicy = "batch";
      systemd.services.nix-daemon.serviceConfig = {
        OOMScoreAdjust = 500;
        ManagedOOMMemoryPressure = "kill";
        ManagedOOMSwap = "kill";
      };

      # Using flakes so have no need for channels.
      nix.channel.enable = false;
    }
  ];
}
