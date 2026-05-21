{ pkgs, lib, ... }:
{
  home.packages = [ pkgs.mypkgs.github-copilot-cli-universal ];

  home.file.".copilot/lsp-config.json".text = builtins.toJSON {
    lspServers.nix = {
      command = lib.getExe pkgs.nil;
      fileExtensions.".nix" = "nix";
    };
  };
}
