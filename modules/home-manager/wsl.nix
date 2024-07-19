{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (config.lib.file) mkOutOfStoreSymlink;

  isWsl =
    (builtins.pathExists /proc/sys/fs/binfmt_misc/WSLInterop)
    || (builtins.pathExists /proc/sys/fs/binfmt_misc/WSLInterop-late);

  windowsHomeDir = builtins.readFile (
    pkgs.runCommandLocal "homedir" {__noChroot = true;}
    ''
      /bin/wslpath "$(/mnt/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe -c '$env:UserProfile')" |
          ${pkgs.coreutils}/bin/tr -d '\r\n' >$out
    ''
  );
  windowsUsername = builtins.readFile (
    pkgs.runCommandLocal "username" {__noChroot = true;}
    ''
      /mnt/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe -c '$env:UserName' |
          ${pkgs.coreutils}/bin/tr -d '\r\n' >$out
    ''
  );

  username =
    if isWsl
    then windowsUsername
    else "adam";
in {
  options.home.isWsl = lib.mkEnableOption "WSL configuration";

  config = lib.mkMerge [
    {home.isWsl = lib.mkDefault isWsl;}

    (lib.mkIf config.home.isWsl {
      home.username = windowsUsername;
      home.homeDirectory = "/home/${windowsUsername}";

      home.file = {
        WinHome = {source = mkOutOfStoreSymlink windowsHomeDir;};
        ".bashrc.d/winget" = {text = "alias winget=winget.exe";};
      };
    })
  ];
}
