{
  config,
  lib,
  pkgs,
  flake,
  ...
}:
let
  calendars = [
    config.accounts.email.accounts.main.address
    "Adam Dinwoodie's Facebook Events"
  ];
in
{
  imports = [
    (lib.mkRemovedOptionModule [ "services" "calendarEmails" ] "")
  ];

  assertions = [
    {
      assertion = config.systemd.user.enable;
      message = ''
        Sending calendar emails requires systemd to be enabled.
      '';
    }
  ];

  systemd.user =
    let
      reportScript = pkgs.mypkgs.writeCheckedShellScript {
        name = "report-calendar.sh";
        text = ''
          calendar_name="$1"
          today="$(${pkgs.coreutils}/bin/date -I)"
          next_month="$(${pkgs.coreutils}/bin/date -I --date='1 month')"
          ${pkgs.gcalcli}/bin/gcalcli \
                  --calendar "$calendar_name" \
                  agenda "$today" "$next_month" |
              ${pkgs.mypkgs.colourmail}/bin/colourmail \
                  -s "Upcoming calendar events in $calendar_name" \
                  -- ${lib.strings.escapeShellArg config.home.username}
        '';
      };
      calConfig =
        cal:
        let
          escapedCal = flake.self.lib.escapeSystemdString cal;
        in
        {
          timers."report-calendar@${escapedCal}" = {
            Unit.Description = "Send periodic calendar events for %I";
            Timer = {
              OnCalendar = "weekly";
              RandomizedDelaySec = "12h";
              RandomizedOffsetSec = "1w";
              AccuracySec = "1d";
              Persistent = true;
            };
            Install.WantedBy = [ "timers.target" ];
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
    lib.mkMerge (map calConfig calendars);
}
