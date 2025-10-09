{pkgs, ...}: {
  services.imapnotify.enable = true;

  accounts.email.accounts.pd.imapnotify = {
    enable = true;
    boxes = ["INBOX"];
    onNotify = pkgs.writeCheckedShellScript {
      name = "test";
      text = ''
        touch ~/boopyboop
      '';
    };
  };
}
