{ pkgs, lib, ... }:
{
  programs.github-copilot-cli = {
    enable = true;
    package = pkgs.mypkgs.github-copilot-cli-universal;

    lspServers.nix = {
      command = lib.getExe pkgs.nil;
      fileExtensions.".nix" = "nix";
    };

    agents.nix-regression-investigator = ./nix-regression-investigator.agent.md;
  };
}
