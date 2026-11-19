{ pkgs, lib, ... }:
{
  programs.github-copilot-cli = {
    enable = true;

    lspServers.nix = {
      command = lib.getExe pkgs.nil;
      fileExtensions.".nix" = "nix";
    };
  };

  nixpkgs.config.allowUnfreePackages = [ "github-copilot-cli" ];
}
