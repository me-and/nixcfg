{
  config,
  lib,
  pkgs,
  ...
}:
{
  # By default, systemd units that send output to stdout or stderr will have
  # the log identifier as the executable.  That's frequently the full Nix store
  # path, or something like `.rclone-wrapped`.  Avoid that by, instead,
  # specifying a default SyslogIdentifier value of the unit name without the
  # ".service" suffix.
  options.systemd.user.services = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule {
        config.Service.SyslogIdentifier = lib.mkDefault "%N";
      }
    );
  };

  config = {
    systemd.user = {
      services = {
        "mail-state@" = {
          Unit.Description = "Unit %i state report";
          Service.Type = "oneshot";
          Service.ExecStart =
            let
              reportScript = pkgs.mypkgs.writeCheckedShellScript {
                name = "mailstate.sh";
                bashOptions = [
                  "errexit"
                  "nounset"
                ];
                text = ''
                  unit="$1"
                  user="$2"
                  shorthost="$3"
                  longhost="$4"

                  unit_state="$(systemctl --user show -PActiveState "$unit")"

                  # shellcheck disable=SC2312 # systemctl expected to return non-zero
                  SYSTEMD_COLORS=True SYSTEMD_URLIFY=False \
                      systemctl --user status "$unit" |
                      ${pkgs.mypkgs.colourmail}/bin/colourmail \
                          -s "Unit $unit $unit_state on $shorthost" \
                          -r "$user on $shorthost <''${user}@''${longhost}>" \
                          -- "$user"
                '';
              };
            in
            "${reportScript} %i %u %l %H";
        };

        disk-usage-report = {
          Unit.Description = "Email a disk usage report";
          Service = {
            Type = "oneshot";
            ExecStart =
              let
                reportScript = pkgs.mypkgs.writeCheckedShellScript {
                  name = "disk-usage-report-mail.sh";
                  runtimeInputs = [ pkgs.mypkgs.disk-usage-report ];
                  text = ''
                    user="$1"
                    shorthost="$2"
                    longhost="$3"

                    disk-usage-report | ${pkgs.mypkgs.colourmail}/bin/colourmail \
                      -r "$user on $shorthost <''${user}@''${longhost}>" \
                      -s "$shorthost disk usage report" \
                      -- "$user"
                  '';
                };
              in
              "${reportScript} %u %l %H";
            KillMode = "process";
          };
        };
      };

      timers.disk-usage-report = {
        Unit.Description = "Send periodic disk usage reports";
        Timer = {
          OnCalendar = "weekly";
          RandomizedDelaySec = "1h";
          AccuracySec = "1h";
          Persistent = true;
        };
        Install.WantedBy = [ "timers.target" ];
      };
    };
  };
}
