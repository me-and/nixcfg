{
  pkgs,
  lib,
  llm-agents,
  ...
}:
{
  programs.github-copilot-cli = {
    enable = true;
    package = llm-agents.packages."${pkgs.stdenv.hostPlatform.system}".copilot-cli;

    lspServers.nix = {
      command = lib.getExe pkgs.nil;
      fileExtensions.".nix" = "nix";
    };

    agents.nix-regression-investigator = ./nix-regression-investigator.agent.md;
  };
}
