{ config, lib, ... }:
{
  options.nix.githubTokenFromSops =
    lib.mkEnableOption "getting the GitHub authentication token for Nix from SOPS"
    // {
      default = true;
    };

  config = lib.mkIf config.nix.githubTokenFromSops {
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

    systemd.services.nix-daemon = {
      serviceConfig.EnvironmentFile = config.sops.templates.nix-daemon-environment.path;
      after = [ "sops-nix.service" ];
    };
    nix.extraOptions = ''
      !include ${config.sops.templates.auth-tokens.path}
    '';
  };
}
