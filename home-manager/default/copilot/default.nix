{ pkgs, lib, ... }:
{
  programs.github-copilot-cli = {
    enable = true;

    lspServers.nix = {
      command = lib.getExe pkgs.nil;
      fileExtensions.".nix" = "nix";
    };

    # TODO Implement and upstream a `skillPackages` attribute or similar, since
    # there's now a well-defined location within each package where the skills
    # should live.
    skills.gh-stack = "${pkgs.gh-stack}/share/skills/gh-stack/gh-stack";

    context = ./copilot-instructions.md;
  };

  nixpkgs.config.allowUnfreePackages = [ "github-copilot-cli" ];
}
