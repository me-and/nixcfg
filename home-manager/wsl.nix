{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (config.lib.file) mkOutOfStoreSymlink;
in {
  home = {
    file.WinHome = { source = mkOutOfStoreSymlink "/mnt/c/Users/${config.home.username}"; };
    shellAliases = {
      winget = "winget.exe";
      wsl = "wsl.exe";
      explorer = "explorer.exe";
    };
  };
}
