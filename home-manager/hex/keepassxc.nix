{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.keepassxc;
in
{
  programs.keepassxc.enable = true;

  xdg.configFile."autostart/org.keepassxc.KeePassXC.desktop".source =
    pkgs.runCommandLocal "org.keepassxc.KeePassXC.desktop"
      {
        # Extra config taken from the values KeePassXC sets itself when set to
        # start automatically.
        extraConfigText = lib.generators.toKeyValue { } {
          X-GNOME-Autostart-enabled = true;
          X-GNOME-Autostart-Delay = 2;
          X-KDE-autostart-after = "panel";
          X-LXQt-Need-Tray = true;
        };
        passAsFile = [ "extraConfigText" ];
      }
      ''
        cat ${cfg.package}/share/applications/org.keepassxc.KeePassXC.desktop "$extraConfigTextPath" >"$out"
      '';
}
