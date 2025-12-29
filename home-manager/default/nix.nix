{
  config,
  lib,
  osConfig,
  ...
}:
{
  options.nix.githubTokenFromSops =
    lib.mkEnableOption "getting the GitHub authentication for Nix from SOPS"
    // {
      default = true;
    };

  config = lib.mkIf config.nix.githubTokenFromSops {
    sops = {
      secrets.github-token = { };
      templates.auth-tokens.content = ''
        access-tokens = github.com=${config.sops.placeholder.github-token}
      '';
    };

    nix = {
      inherit (osConfig.nix) package;
      extraOptions = ''
        !include ${config.sops.templates.auth-tokens.path}
      '';
    };
  };
}
