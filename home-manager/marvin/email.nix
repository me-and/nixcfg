{ config, pkgs, ... }:
let
  accountsCfg = config.accounts.email.accounts;
in
{
  services.goimapnotify.enable = true;
  accounts.email.accounts.main = {
    passwordCommand =
      let
        secretPath = config.sops.secrets."email/${accountsCfg.main.address}/offlineimap".path;
      in
      "${pkgs.coreutils}/bin/cat ${secretPath}";
    goimapnotify = {
      enable = true;
      boxes = {
        INBOX.onNewMail = "${config.home.homeDirectory}/.local/bin/mailsync -i";
        TaskWarrior.onNewMail = "${config.home.homeDirectory}/.local/bin/mailsync TaskWarrior";
      };
    };
  };
}
