{ plasma-manager, pkgs, ... }:
{
  imports = [ plasma-manager.homeModules.plasma-manager ];

  home.packages = [ pkgs.mypkgs.rc2nix ];

  programs.plasma = {
    enable = true;
    overrideConfig = true;

    configFile.kwalletrc.Wallet.Enabled = false;
  };
}
