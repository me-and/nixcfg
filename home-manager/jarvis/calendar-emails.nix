{
  config,
  lib,
  mylib,
  pkgs,
  ...
}:
let
  calendars = [
    config.accounts.email.accounts.main.address
    "Adam Dinwoodie's Facebook Events"
  ];
in
{
  sops = {
    secrets."gcalcli/client-id" = { };
    secrets."gcalcli/client-secret" = { };
    templates.gcalclirc = {
      content = ''
        --client-id=${config.sops.placeholder."gcalcli/client-id"}
        --client-secret=${config.sops.placeholder."gcalcli/client-secret"}
        --default-calendar=${config.accounts.email.primaryAccount.userName}
      '';
      path = "${config.xdg.configHome}/gcalcli/gcalclirc";
    };
  };

  systemd.user =
    let
      reportScript = pkgs.mypkgs.writeCheckedShellScript {
        name = "report-calendar.sh";
        text = ''
          date () { ${lib.getExe' pkgs.coreutils "date"} "$@"; }
          gcalcli () { ${lib.getExe pkgs.gcalcli} "$@"; }
          colourmail () { ${lib.getExe pkgs.mypkgs.colourmail} "$@"; }

          calendar_name="$1"
          today="$(date -I)"
          next_month="$(date -I --date='1 month')"
          gcalcli \
                  --calendar "$calendar_name" \
                  agenda "$today" "$next_month" |
              colourmail \
                  -s "Upcoming calendar events in $calendar_name" \
                  -- ${lib.strings.escapeShellArg config.home.username}
        '';
      };
      calConfig =
        cal:
        let
          escapedCal = mylib.escapeSystemdString cal;
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
            Unit = {
              Description = "Email upcoming calendar events for %I";
              After = [ "sops-nix.service" ];
            };
            Service = {
              Type = "oneshot";
              ExecStart = "${reportScript} %I";
            };
          };
        };
    in
    lib.mkMerge (map calConfig calendars);
}
