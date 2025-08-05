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
      (dontLink "https://github.com/me-and/nixcfg")
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
          bashOptions = ["nounset" "pipefail"]; # No errexit
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
            rcs=("''${PIPESTATUS[@]}")
            if (( rcs[1] != 0 )); then
                exit "''${rcs[1]}"
            elif (( rcs[2] != 0 )); then
                exit "''${rcs[2]}"
            fi

            # From ~/.homesick/repos/homeshick/lib/exit_status.sh
            declare -ir EX_AHEAD=85 EX_BEHIND=86 EX_MODIFIED=88
            if (( rcs[0] == EX_AHEAD || rcs[0] == EX_BEHIND || rcs[0] == EX_MODIFIED )); then
                # Expected non-zero return code from homeshick, so return 0 from this script
                exit 0
            fi
            exit "''${rcs[0]}"
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
        RandomizedOffsetSec = "1d";
        AccuracySec = "6h";
        Persistent = true;
      };
    };
  };
}
