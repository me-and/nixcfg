{
  config,
  lib,
  pkgs,
  personalCfg,
  ...
}:
{
  imports = [ personalCfg.homeModules.latex ];

  home.stateVersion = "25.11";

  home.file.".config/systemd/user/timers.target.wants/disk-usage-report.timer".source =
    config.home.file.".config/systemd".source + "/user/disk-usage-report.timer";

  home.packages = [
    pkgs.mypkgs.wavtoopus
    pkgs.quodlibet-without-gst-plugins # operon
  ];

  accounts.email.maildirBasePath = "${config.xdg.cacheHome}/mail";
  programs.offlineimap.enable = true;

  services.goimapnotify.enable = true;
  accounts.email.accounts.main.passwordCommand = "${pkgs.coreutils}/bin/cat ${
    config.sops.secrets."email/${config.accounts.email.accounts.main.address}/offlineimap".path
  }";
  accounts.email.accounts.main.goimapnotify.enable = true;
  accounts.email.accounts.main.goimapnotify.boxes.INBOX = {
    onNewMail = pkgs.mypkgs.writeCheckedShellScript {
      name = "nope";
      text = ''
        exit 1
      '';
    };
  };

  services.syncthing.enable = true;
}
