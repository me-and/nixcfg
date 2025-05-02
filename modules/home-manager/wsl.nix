{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (config.lib.file) mkOutOfStoreSymlink;

in {
  imports = [(lib.mkRenamedOptionModule ["home" "isWsl"] ["home" "wsl" "enable"])];

  options.home.wsl = {
    enable = lib.mkEnableOption "WSL configuration";
    windowsUsername = lib.mkOption {
      default = config.home.username;
      defaultText = "config.home.username";
      type = lib.types.str;
    };
    windowsHomeDir = lib.mkOption {
      default = "/mnt/c/Users/${config.home.wsl.windowsUsername}";
      defaultText = "/mnt/c/Users/\${config.home.wsl.windowsUsername}";
      type = lib.types.str;
    };
  };

  config = lib.mkIf config.home.wsl.enable {
    home.file = {
      WinHome = {source = mkOutOfStoreSymlink config.home.wsl.windowsHomeDir;};
      OneDrive = {source = mkOutOfStoreSymlink "${config.home.homeDirectory}/WinHome/OneDrive";};
      ".bashrc.d/winexealiases".text = ''
        alias winget=winget.exe
        alias wsl=wsl.exe
        alias explorer=explorer.exe
      '';
    };
  };
}
