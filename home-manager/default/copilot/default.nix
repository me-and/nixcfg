{ pkgs, lib, ... }:
{
  programs.github-copilot-cli = {
    enable = true;

    lspServers.nix = {
      command = lib.getExe pkgs.nil;
      fileExtensions.".nix" = "nix";
    };

    agents.nix-regression-investigator = ./nix-regression-investigator.agent.md;
  };

  nixpkgs.config.allowUnfreePackages = [ "github-copilot-cli" ];
}
