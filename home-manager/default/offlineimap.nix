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
            util-linux
          ];
          text = ''
            [[ -v MAINPID ]] || exit 0

            if ! offlineimap_pid="$(pgrep -P "$MAINPID" -o offlineimap)"; then
                offlineimap_pid="$MAINPID"
            fi

            kill "$offlineimap_pid"
            rc=0
            waitpid --timeout "$(( 8 * 60 ))" "$MAINPID" || rc="$?"
            (( rc == 3 )) || exit "$rc"

            kill "$offlineimap_pid"
            kill "$offlineimap_pid"
            kill "$offlineimap_pid"
            exec waitpid --timeout 60 "$MAINPID"
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
                StartLimitIntervalSec = "5min";
                StartLimitBurst = 3;
              };
              Service = {
                UMask = "077";
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
                RestartForceExitStatus = [
                  "SIGHUP"
                  "SIGTERM"
                  "SIGINT"
                  "SIGPIPE"
                ];
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
                StartLimitIntervalSec = "5min";
                StartLimitBurst = 5;
              };
              Service = {
                UMask = "077";
                StandardInput = "socket";
                StandardOutput = "journal";
                StandardError = "journal";
                TimeoutStopSec = "10m";
                RestartForceExitStatus = [
                  "SIGHUP"
                  "SIGTERM"
                  "SIGINT"
                  "SIGPIPE"
                ];
                ExecStart = pkgs.mypkgs.writeCheckedShellScript {
                  name = "sync-offlineimap-folder-${name}.sh";
                  runtimeInputs = [
                    pkgs.util-linux
                    config.programs.offlineimap.package
                  ];
                  text = ''
                    maildir=${lib.escapeShellArg maildir}
                    mkdir -p -- "$maildir"
                    exec {maildir_fd}<"$maildir"

                    while :; do
                        labels=()
                        while read -rt0; do
                            # Get the flock for the mail folder now if we don't
                            # already have it.  If we waited until we were
                            # actually syncing, and we end up waiting a while
                            # for some other process to release the lock, other
                            # labels might be added to the list to sync while
                            # we're waiting.  This way, we can sync those
                            # folders in parallel.
                            flock -x "$maildir_fd"

                            read -r label
                            labels+=("$label")
                        done

                        (( "''${#labels[*]}" > 0 )) || exit 0
                        IFS=,;
                        printf "labels: %s\n" "''${labels[*]}"
                        offlineimap -u basic -o -k mbnames:enabled=no -a ${lib.escapeShellArg name} -f "''${labels[*]}"

                        # Release the lock on the mail folder.  We might be
                        # about to grab it again, but this gives other
                        # processes that might be waiting for the lock a chance
                        # to grab it.
                        flock -u "$maildir_fd"
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
