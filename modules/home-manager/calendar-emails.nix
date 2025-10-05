{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.calendarEmails;
in {
  options.services.calendarEmails = {
    enable = lib.mkEnableOption "sending emails of upcoming appointments";
    calendars = lib.mkOption {
      description = ''
        List of calendar names to generate email reports for.
      '';
      type = lib.types.listOf lib.types.str;
      default = [];
    };
    destination = lib.mkOption {
      description = "Account or email address to send the reports to.";
      type = lib.types.str;
      default = config.home.username;
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = config.systemd.user.enable;
        message = ''
          Sending calendar emails requires systemd to be enabled.
        '';
      }
    ];

    systemd.user = let
      reportScript = pkgs.mypkgs.writeCheckedShellScript {
        name = "report-calendar.sh";
        text = ''
          calendar_name="$1"
          today="$(${pkgs.coreutils}/bin/date -I)"
          next_month="$(${pkgs.coreutils}/bin/date -I --date='1 month')"
          ${pkgs.gcalcli}/bin/gcalcli \
                  --calendar "$1" \
                  agenda "$today" "$next_month" |
              ${pkgs.mypkgs.colourmail}/bin/colourmail \
                  -s "Upcoming calendar events in $calendar_name" \
                  -- ${lib.strings.escapeShellArg cfg.destination}
        '';
      };
      calConfig = cal: let
        escapedCal = pkgs.escapeSystemdString cal;
      in {
        timers."report-calendar@${escapedCal}" = {
          Unit.Description = "Send periodic calendar events for %I";
          Timer = {
            OnCalendar = "weekly";
            RandomizedDelaySec = "12h";
            RandomizedOffsetSec = "1w";
            AccuracySec = "1d";
            Persistent = true;
          };
          Install.WantedBy = ["timers.target"];
        };
        services."report-calendar@${escapedCal}" = {
          Unit.Description = "Email upcoming calendar events for %I";
          Service = {
            Type = "oneshot";
            ExecStart = "${reportScript} %I";
          };
        };
      };
    in
      lib.mkMerge (map calConfig cfg.calendars);
  };
}
