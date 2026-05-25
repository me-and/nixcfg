{ config, lib, ... }:
{
  options.nix.githubTokenFromSops =
    lib.mkEnableOption "getting the GitHub authentication token for Nix from SOPS"
    // {
      default = true;
    };

  config = lib.mkMerge [
    (lib.mkIf config.nix.githubTokenFromSops {
      sops = {
        # Allow the user to read this secret directly for tools such as the
        # Copilot CLI container wrapper.  Root can still read it regardless of
        # ownership, so the nix-daemon EnvironmentFile below still works.
        secrets.github-token = {
          owner = config.users.me;
        };
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
