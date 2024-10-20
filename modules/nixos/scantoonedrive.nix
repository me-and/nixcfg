{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (builtins) toString;

  cfg = config.services.scanToOneDrive;
in {
  options.services.scanToOneDrive = {
    enable =
      lib.mkEnableOption
      "copying documents sent from my scanner to OneDrive";

    ftpPasvPortRange = lib.mkOption {
      description = "Port range to use for FTP PASV connections.";
      type = lib.types.submodule {
        options.from = lib.mkOption {type = lib.types.ints.u16;};
        options.to = lib.mkOption {type = lib.types.ints.u16;};
      };
    };

    scannerUser = lib.mkOption {
      description = "Username to use for uploading from the scanner.";
      type = lib.types.str;
    };
    scannerGroup = lib.mkOption {
      description = "Group name to use for uploading from the scanner.";
      type = lib.types.str;
      default = cfg.scannerUser;
    };

    scannerHomeDir = lib.mkOption {
      description = "Home directory for the scanner user.";
      type = lib.types.path;
      default = "/var/tmp/${cfg.scannerUser}";
    };
    scannerDestDir = lib.mkOption {
      description = "Directory that will actually be used for uploads.";
      type = lib.types.path;
      default = cfg.scannerHomeDir;
    };

    scannerHashedPasswordFile = lib.mkOption {
      description = ''
        Path to the file containing the scanner user's hashed password.
      '';
      type = lib.types.path;
      apply = toString;
    };

    openPorts = lib.mkOption {
      description = "Whether to open the necessary firewall ports.";
      type = lib.types.bool;
      default = true;
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.ftpPasvPortRange.from <= cfg.ftpPasvPortRange.to;
        message = "Invalid port range specified.";
      }
    ];

    # Set up the user account the scanner will use to log in with.
    users.users."${cfg.scannerUser}" = {
      description = "Printer scanner upload account";
      isSystemUser = true;
      group = cfg.scannerGroup;
      home = cfg.scannerHomeDir;
      createHome = true;
      hashedPasswordFile = cfg.scannerHashedPasswordFile;
    };
    users.groups."${cfg.scannerGroup}" = {};
    users.groups.rclone.members = [cfg.scannerUser];

    # Set up the FTP server that the scanner will log into.
    services.vsftpd = {
      enable = true;
      writeEnable = true;
      userlistEnable = true;
      userlist = [cfg.scannerUser];
      localUsers = true;
      extraConfig = ''
        connect_from_port_20=YES
        pasv_min_port=${toString cfg.ftpPasvPortRange.from}
        pasv_max_port=${toString cfg.ftpPasvPortRange.to}
      '';
    };

    # Set up the firewall so the connections work.
    networking.firewall = lib.mkIf cfg.openPorts {
      # Standard ftp ports
      allowedTCPPorts = [20 21];

      # Ports for PASV ftp connections
      allowedTCPPortRanges = [cfg.ftpPasvPortRange];
    };

    # Set up the subdirectory that the scanner will upload files to.
    systemd.tmpfiles.rules = [
      "d '${cfg.scannerDestDir}' 0700 ${cfg.scannerUser} ${cfg.scannerGroup}"
    ];

    # Set up the systemd service that will copy files from the FTP directory to
    # OneDrive.
    systemd.services.ftp-to-onedrive = {
      description = "uploading scanned documents to OneDrive";
      unitConfig.RequiresMountsFor = cfg.scannerDestDir;
      serviceConfig = {
        Type = "oneshot";
        WorkingDirectory = cfg.scannerDestDir;
        CacheDirectory = "rclone";
        CacheDirectoryMode = "0770";
        ConfigurationDirectory = "rclone";
        ConfigurationDirectoryMode = "0770";
        User = cfg.scannerUser;
        Group = "rclone";
        ExecStart = pkgs.writeCheckedShellScript {
          name = "ftp-to-onedrive.sh";
          runtimeInputs = [
            pkgs.lsof
            pkgs.rclone
            pkgs.system-sendmail
            pkgs.coreutils
          ];
          runtimeEnv = {
            MAIL_USER = config.users.me;
          };
          purePath = true;
          text = ''
            shopt -s nullglob
            for ext in pdf jpg; do
                for file in *."$ext"; do
                    # Wait until two separate invocations of lsof, spaced by a
                    # couple of seconds, have failed to spot anything with this
                    # file open.  When just waiting for nothing to have the
                    # file open, I've seen occasional uploads of empty files,
                    # so this loop adds a bit of delay to hopefully avoid that.
                    no_open_file_count=0
                    while (( no_open_file_count < 2 )); do
                        sleep 2
                        rc=0
                        lsof -f +r -Fpn -w -- "$file" || rc="$?"
                        if (( rc == 0 )); then
                            # Saw something that had the file open.  The file
                            # has now closed, but I don't entirely trust
                            # something to not open it again.
                            no_open_file_count=0
                        elif (( rc == 1 )); then
                            # Nothing had the file open.
                            no_open_file_count=$(( no_open_file_count + 1 ))
                        else
                            # Unexpected return code, e.g. because Bash
                            # couldn't find lsof.
                            exit "$rc"
                        fi
                    done

                    basename="''${file%."$ext"}"

                    if [[ "$ext" = jpg ]]; then
                        # The final part of the basename has the page number.
                        # Extract that and normalise the basename to one
                        # without the page number.
                        page="''${basename: -3}"
                        basename="''${basename::-4}"
                    else
                        page=""
                    fi

                    # The final part of the filename has the timestamp and job
                    # number from the scanner.
                    Y="''${basename: -14:4}"
                    M="''${basename: -10:2}"
                    D="''${basename: -8:2}"
                    hms="''${basename: -6}"
                    scan_timestamp="''${Y}-''${M}-''${D}T''${hms}"
                    job="''${basename: -20:6}"
                    origname="''${basename::-20}"

                    # The original name is made up of multiple parts separated by
                    # "==".
                    declare -a nameparts=()
                    while [[ "$origname" = *==* ]]; do
                        nameparts+=("''${origname%%==*}")
                        origname="''${origname#*==}"
                    done
                    nameparts+=("$origname")

                    if (( "''${#nameparts[*]}" == 1 )); then
                        # Only one part to the name, so it defines the directory
                        # the file is copied to.
                        destdir="''${nameparts[0]}"
                        destbasename="''${scan_timestamp} scan ''${job}"
                    elif (( "''${#nameparts[*]}" == 2 )); then
                        # There are two parts to the name.  The first is the
                        # destination directory, the second will contain either or
                        # both of a descriptive file name or a date or datetime to
                        # use for filing.
                        destdir="''${nameparts[0]}"
                        if [[ "''${nameparts[1]}" =~ ^[12][0-9][0-9][0-9]-[012][0-9]-[0-3][0-9]
                            || "''${nameparts[1]}" =~ ^[12][0-9][0-9][0-9]-[012][0-9]-[0-3][0-9]T[0-2][0-9][0-5][0-9]
                            || "''${nameparts[1]}" =~ ^[12][0-9][0-9][0-9]-[012][0-9]-[0-3][0-9]T[0-2][0-9][0-5][0-9][0-6][0-9]
                            ]]; then
                            # This part is either just a timestamp or a timestamp and
                            # description.  In either case, we want the filename to
                            # start with that.
                            destbasename="''${nameparts[1]} scan ''${job} on ''${scan_timestamp}"
                        else
                            # This part is just a description, so use the timestamp
                            # from the scan.
                            destbasename="''${scan_timestamp} ''${nameparts[1]} scan ''${job}"
                        fi
                    else
                        echo "Unrecognised filename format ''${nameparts[*]}" >&2
                        exit 1
                    fi

                    # In all cases, the destination directory may have single "="
                    # as directory seperators.
                    destdir="''${destdir//=/\/}"

                    # If the destination starts with Desktop, put it there,
                    # otherwise put it in the Communications directory.
                    if [[ "$destdir" = Desktop || "$destdir" = Desktop/* ]]; then
                        fulldest=onedrive:"$destdir"/"$destbasename"
                    else
                        fulldest=onedrive:Documents/Communications/"$destdir"/"$destbasename"
                    fi

                    # If there's a page number, add that to the filename.
                    if [[ "$page" ]]; then
                        fulldest+=" p''${page##+(0)}"
                    fi

                    # Add the file extension.
                    fulldest+=".$ext"

                    # Check there's nothing untoward in the environment before we
                    # start running commands.
                    if [[ ! "$MAIL_USER" =~ ^[A-Za-z0-9]+$
                        || ! "$file" =~ ^[A-Za-z0-9_-][A-Za-z0-9' &'.,=_-]*\."$ext"$
                        || ! "$fulldest" =~ ^onedrive:([A-Za-z0-9_-]([A-Za-z0-9' &'.,=_-]*[A-Za-z0-9_-])?/)*[A-Za-z0-9_-][A-Za-z0-9' &'.,=_-]*."$ext"$
                        ]]; then
                        echo 'Unexpected value in one of the below' >&2
                        declare -p MAIL_USER file fulldest >&2
                        exit 1
                    fi

                    # Upload the file
                    rclone \
                        --config="''${CONFIGURATION_DIRECTORY}/rclone.conf" \
                        --cache-dir="''${CACHE_DIRECTORY}" \
                        moveto "$file" "$fulldest"

                    # Send a notification that the file has been uploaded
                    sendmail -odi -i -t <<EOF
            To: $MAIL_USER
            Subject: Copied $file from ftp directory to OneDrive

            Destination $fulldest
            EOF
                done
            done
          '';
        };
      };

      # TODO Add in the check-domain-resolvable@1drv.ms.service wants/after
      # dependencies.
    };

    # Set up the systemd path unit that will start the service when files get
    # uploaded.
    systemd.paths.ftp-to-onedrive = {
      description = "monitoring for scanned documents to upload to OneDrive";
      wantedBy = ["paths.target"];
      unitConfig.RequiresMountsFor = cfg.scannerDestDir;
      pathConfig.PathExistsGlob = [
        "${cfg.scannerDestDir}/*.pdf"
        "${cfg.scannerDestDir}/*.jpg"
      ];
    };
  };
}
