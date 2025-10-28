{ config, pkgs, ... }:
{
  programs.steam = {
    enable = true;
    extraPackages = with pkgs; [
      gamemode
      gamescope
    ];
    gamescopeSession.enable = true;
    protontricks.enable = true;
  };

  programs.gamescope = {
    enable = true;
    capSysNice = true;
  };

  programs.gamemode = {
    enable = true;
    settings.general.renice = 10;
  };
  users.groups.gamemode.members = [ config.users.me ];

  users.users."${config.users.me}".packages =
    let
      heroic = pkgs.heroic.override {
        extraPkgs =
          pkgs: with pkgs; [
            gamemode
            gamescope
          ];
      };
    in
    [ heroic ];
}
