{
  config,
  lib,
  mylib,
  pkgs,
  ...
}:
lib.mkIf config.programs.offlineimap.enable {
  systemd.user = {
    services =
      let
        accountNames = builtins.attrNames (lib.filterAttrs (n: v: v.enable) config.accounts.email.accounts);
        stopSyncScript = pkgs.mypkgs.writeCheckedShellScript {
          name = "stop-sync-offlineimap.sh";
          runtimeInputs = with pkgs; [
            procps
            coreutils
          ];
          text = ''
            [[ -v MAINPID ]] || exit 0
            pkill -P "$MAINPID" -xo offlineimap
            rc=0
            timeout 8m tail -f --pid "$MAINPID" /dev/null || rc="$?"
            if (( rc == 124 )); then
                pkill -P "$MAINPID" -xo offlineimap
                pkill -P "$MAINPID" -xo offlineimap
                pkill -P "$MAINPID" -xo offlineimap
                exec timeout 1m tail -f --pid "$MAINPID"
            else
                exit "$rc"
            fi
          '';
        };
        perAccountServices =
          name:
          let
            maildir = config.accounts.email.accounts."${name}".maildir.absPath;
          in
          {
            "offlineimap-full@${mylib.escapeSystemdString name}" = {
              Unit = {
                Description = "Sync of all labels for account %I";
                After = [ "sops-nix.service" ];
              };
              Service = {
                UMask = "077";
                Type = "oneshot";
                TimeoutStopSec = "10m";
                ExecStart = pkgs.mypkgs.writeCheckedShellScript {
                  name = "sync-offlineimap-${name}.sh";
                  runtimeInputs = [
                    pkgs.util-linux
                    config.programs.offlineimap.package
                  ];
                  text = ''
                    mkdir -p -- ${lib.escapeShellArg maildir}
                    exec flock -Fx ${lib.escapeShellArg maildir} offlineimap -u basic -o -a ${lib.escapeShellArg name}
                  '';
                };
                SuccessExitStatus = [ "SIGTERM" ];
                ExecStop = stopSyncScript;
              };
            };

            "offlineimap-folder@${mylib.escapeSystemdString name}" = {
              Unit = {
                Description = "Sync of requested labels for account %I";
                Requires = [ "offlineimap-folder@%i.socket" ];
                After = [
                  "offlineimap-folder@%i.socket"
                  "sops-nix.service"
                ];
              };
              Service = {
                UMask = "077";
                Type = "oneshot";
                StandardInput = "socket";
                StandardOutput = "journal";
                StandardError = "journal";
                TimeoutStopSec = "10m";
                SuccessExitStatus = [ "SIGTERM" ];
                ExecStart = pkgs.mypkgs.writeCheckedShellScript {
                  name = "sync-offlineimap-folder-${name}.sh";
                  runtimeInputs = [
                    pkgs.util-linux
                    config.programs.offlineimap.package
                  ];
                  text = ''
                    mkdir -p -- ${lib.escapeShellArg maildir}
                    while :; do
                        labels=()
                        while read -rt1 label; do
                            labels+=("$label")
                        done
                        (( "''${#labels[*]}" > 0 )) || exit 0
                        IFS=,;
                        printf "labels: %s\n" "''${labels[*]}"
                        flock -Fx ${lib.escapeShellArg maildir} offlineimap -u basic -o -k mbnames:enabled=no -a ${lib.escapeShellArg name} -f "''${labels[*]}"
                    done
                  '';
                };
                ExecStop = stopSyncScript;
              };
            };
          };

        # Services where systemd instantiation gives all the granularity we need.
        sharedServices = {
          "offlineimap-selected-folder@" = {
            # Instance name will be the systemd-escaped account name and
            # systemd-escaped folder to sync, separated by `::`.
            Unit = {
              Description = "Sync a specific folder %i";
              After = [ "sops-nix.service" ];
            };
            Service = {
              UMask = "077";
              Type = "oneshot";
              ExecStart =
                let
                  script = pkgs.mypkgs.writeCheckedShellScript {
                    name = "sync-offlineimap-account-folder.sh";
                    runtimeInputs = [ pkgs.systemd ];
                    text = ''
                      account="$(systemd-escape -u "''${1%%::*}")"
                      folder="$(systemd-escape -u "''${1#*::}")"
                      folder="''${folder//&/&-}"
                      socket_unit="$(systemd-escape --template offlineimap-folder@.socket "$account")"
                      systemctl --user start "$socket_unit"
                      socket_property="$(systemctl --user show -PListen "$socket_unit")"
                      socket_path="''${socket_property% *}"
                      echo "$folder" >"$socket_path"
                    '';
                  };
                in
                "${script} %i";
            };
          };
        };
      in
      lib.mkMerge ((map perAccountServices accountNames) ++ [ sharedServices ]);

    sockets = {
      "offlineimap-folder@" = {
        Unit.Description = "Socket for triggering OfflineIMAP folder sync for account %I";
        Socket.ListenFIFO = "%t/offlineimapsync/%i";
        Socket.SocketMode = "0600";
      };
    };
  };
}
