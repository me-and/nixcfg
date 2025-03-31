{pkgs, ...}: {
  homeshick = let
    doLink = url: {inherit url;};
    dontLink = url: {
      inherit url;
      link = false;
    };
  in {
    enable = true;
    repos = [
      (doLink "https://github.com/me-and/castle")
      (dontLink "https://github.com/me-and/nixcfg")
      (dontLink "https://github.com/me-and/asmodeus")
      (dontLink "https://github.com/magicmonty/bash-git-prompt")
    ];
  };

  systemd.user = {
    services.homeshick-report = {
      Unit = {
        Description = "Email a Homeshick status report";
        Wants = ["resolve-host-a@github.com.service"];
        After = ["resolve-host-a@github.com.service"];
      };
      Service = {
        Type = "oneshot";
        Environment = [
          "USER=%u"
          "LONGHOST=%H"
          "SHORTHOST=%l"
        ];
        ExecStart = pkgs.writeCheckedShellScript {
          name = "homeshick-report.sh";
          purePath = true;
          runtimeInputs = with pkgs; [
            coreutils
            gnused
            moreutils
            colourmail
            bash
            git
            findutils
          ];
          text = ''
            SUBJECT="Homeshick status report from $SHORTHOST"
            FROM="$USER on $SHORTHOST <$USER@$LONGHOST>"
            chronic ~/.homesick/repos/homeshick/bin/homeshick check |&
                sed "s/^.*\\r//" |
                ifne colourmail -s "$SUBJECT" -r "$FROM" -- "$USER"
          '';
        };
        KillMode = "process";
      };
    };

    timers.homeshick-report = {
      Unit.Description = "Email daily Homeshick status reports";
      Install.WantedBy = ["timers.target"];
      Timer = {
        OnCalendar = "00:00";
        RandomizedDelaySec = "1h";
        AccuracySec = "6h";
        Persistent = true;
      };
    };
  };
}
