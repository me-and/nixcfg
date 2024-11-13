{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.programs.keepassxc;

  # https://github.com/NixOS/nixpkgs/blob/64b80bfb316b57cdb8919a9110ef63393d74382a/nixos/lib/systemd-lib.nix#L59C3-L60C1
  unitNameType = lib.types.strMatching "[a-zA-Z0-9@%:_.\\-]+[.](service|socket|device|mount|automount|swap|target|path|timer|scope|slice)";
in {
  options.programs.keepassxc = {
    enable = lib.mkEnableOption "KeePassXC";
    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.keepassxc;
      description = "The KeePassXC package to use.";
    };
    autostart = {
      enable = lib.mkEnableOption "automatically starting KeePassXC";
      extraConfig = lib.mkOption {
        # TODO Get this to pull the data out of KeePassXC itself.
        type = with lib.types; attrsOf (oneOf [bool int str]);
        description = ''
          Extra attributes to add to the autostart .desktop entry.

          The default value is taken from the one created by KeePassXC when
          setting it to start automatically.
        '';
        default = {
          X-GNOME-Autostart-enabled = true;
          X-GNOME-Autostart-Delay = 2;
          X-KDE-autostart-after = "panel";
          X-LXQt-Need-Tray = true;
        };
      };
      after = lib.mkOption {
        type = lib.types.listOf unitNameType;
        description = "User systemd units that must be started before KeePassXC.";
        default = [];
      };
      before = lib.mkOption {
        type = lib.types.listOf unitNameType;
        description = "User systemd units that must be started after KeePassXC.";
        default = [];
      };
      wants = lib.mkOption {
        type = lib.types.listOf unitNameType;
        description = "User systemd units that KeePassXC wants to also be running.";
        default = [];
      };
      requires = lib.mkOption {
        type = lib.types.listOf unitNameType;
        description = "User systemd units that KeePassXC requires to also be running.";
        default = [];
      };
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [cfg.package];

    xdg.configFile = lib.mkIf cfg.autostart.enable {
      "autostart/org.keepassxc.KeePassXC.desktop".source = let
      in
        pkgs.runCommandLocal "org.keepassxc.KeePassXC.desktop" {
          extraConfigText = lib.generators.toKeyValue {} cfg.autostart.extraConfig;
          passAsFile = ["extraConfigText"];
        }
        ''
          cat ${cfg.package}/share/applications/org.keepassxc.KeePassXC.desktop "$extraConfigTextPath" >"$out"
        '';

      # This assumes we're using the systemd XDG autostart generator.  I've no
      # idea how to make this work if we're not...
      "systemd/user/app-org.keepassxc.KeePassXC@autostart.service.d/keepassxc.nix.conf" = {
        enable =
          (cfg.autostart.before != [])
          || (cfg.autostart.after != [])
          || (cfg.autostart.wants != [])
          || (cfg.autostart.requires != []);

        text =
          lib.generators.toINI {listsAsDuplicateKeys = true;}
          {
            Unit = {
              Before = cfg.autostart.before;
              After = cfg.autostart.after;
              Wants = cfg.autostart.wants;
              Requires = cfg.autostart.requires;
            };
          };
      };
    };
  };
}
