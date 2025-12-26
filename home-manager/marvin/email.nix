{ config, pkgs, ... }:
let
  accountsCfg = config.accounts.email.accounts;
in
{
  programs.offlineimap.enable = true;

  home.packages = [ pkgs.mypkgs.mailsync ];

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
        INBOX.onNewMail = "${pkgs.mypkgs.mailsync}/bin/mailsync -i";
        TaskWarrior.onNewMail = "${pkgs.mypkgs.mailsync}/bin/mailsync TaskWarrior";
      };
    };
  };
}
