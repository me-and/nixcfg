{ plasma-manager, pkgs, ... }:
{
  imports = [ plasma-manager.homeModules.plasma-manager ];

  home.packages = [ pkgs.mypkgs.rc2nix ];

  programs.plasma = {
    enable = true;
    overrideConfig = true;

    configFile.kwalletrc.Wallet.Enabled = false;
  };

  # https://github.com/nix-community/home-manager/issues/1586#issuecomment-3446198028
  programs.firefox.nativeMessagingHosts = [ pkgs.kdePackages.plasma-browser-integration ];
}
