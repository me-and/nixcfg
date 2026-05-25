{
  config,
  lib,
  pkgs,
  ...
}:
{
  systemd.services.disk-usage-report = {
    description = "Email a disk usage report";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.mypkgs.writeCheckedShellScript {
        name = "disk-usage-report-mail.sh";
        runtimeInputs = [
          config.nix.package
        ]
        ++ (with pkgs.mypkgs; [
          disk-usage-report
          colourmail
        ]);
        text =
          let
            subject = "${config.networking.hostName} disk usage report";
            from = "${config.networking.hostName} <root@${config.networking.fqdn}>";
          in
          ''
            disk-usage-report |
              colourmail \
                -r ${lib.escapeShellArg from} \
                -s ${lib.escapeShellArg subject} \
                -- ${lib.escapeShellArg config.users.me}
          '';
      };
      Nice = 12;
    };
  };

  systemd.timers.disk-usage-report = {
    description = "Periodically email disk usage reports";
    timerConfig = {
      OnCalendar = "weekly";
      RandomizedOffsetSec = "7d";
      RandomizedDelaySec = "1h";
      AccuracySec = "1d";
      Persistent = true;
    };
    wantedBy = [ "timers.target" ];
  };
}
