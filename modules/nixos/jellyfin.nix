{
  config,
  lib,
  options,
  pkgs,
  ...
}: let
  cfg = config.services.jellyfin;
  opt = options.services.jellyfin;

  inherit (builtins) toString;
  inherit (lib.strings) escapeShellArg escapeShellArgs;

  writeJsonFile = filename: json:
    pkgs.writeText filename (builtins.toJSON json);
in {
  options.services.jellyfin = let
    inherit (lib) mkEnableOption mkOption;
    inherit (lib.types) attrsOf bool enum ints listOf oneOf path str submodule;
  in {
    virtualHost = {
      enable =
        mkEnableOption "an Nginx virtual host for access to the server";
      fqdn = mkOption {
        description = "FQDN on which to provide the Jellfin server";
        example = "example.org";
        type = str;
      };
      forceSecureConnections = mkOption {
        description = "Whether to redirect HTTP connections to HTTPS.";
        type = bool;
        default = false;
      };
      enableACME = mkOption {
        description = ''
          Whether to use ACME to generate TLS certificates for the server.

          This will look after the basic configuration for the configured
          domain within the `security.acme` configuration, but you will still
          need to configure `security.acme` to accept the ACME terms and to
          prove ownership of the domain.
        '';
        type = bool;
        default = false;
      };
      internalPort = mkOption {
        description = ''
          The internal port to use to connect to the Jellyfin server.  This is
          configured as part of the Jellyfin server setup, and means that the
          server will not be accessible until the initial server configuration
          is complete.
        '';
        type = ints.u16;
        # Default selected at random, excluding all the ports that were listed at
        # https://en.wikipedia.org/w/index.php?title=List_of_TCP_and_UDP_port_numbers&oldid=1237031823
        default = 16896;
      };
    };

    # TODO Configure these if they change after the initial configuration, as
    # well as during the setup wizard.
    localisation = {
      ui = mkOption {
        description = "User interface culture code.";
        example = "en-US";
        default = "en-GB";
        type = str;
      };

      metadataCountryCode = mkOption {
        description = "Metadata country code.";
        example = "US";
        default = "GB";
        type = str;
      };

      preferredMetadataLanguage = mkOption {
        description = "Metadata language code.";
        example = "fr";
        default = "en";
        type = str;
      };
    };

    users.initialUser = {
      name = mkOption {
        description = ''
          Initial user's username.

          This user will be the first user created if the Jellyfin server has
          not previously been configured.  It is also the user that will be
          used for setting all other Jellyfin configuration, so it must be an
          administrator account.
        '';
        example = "jellyfin";
        type = str;
      };
      passwordFile = mkOption {
        description = ''
          Path to a file containing the initial user's password.

          This will be configured on Jellyfin when the server is initially
          configured.  It will also be used after the initial Jellyfin server
          setup to make sure the server configuration matches the NixOS
          configuration.
        '';
        example = /etc/nixos/secrets/jellyfin-user-pw;
        type = path;
        apply = toString;
      };
    };

    overrideLibraries = mkOption {
      type = bool;
      description = ''
        Whether to override existing libraries with the defined configuration.

        If `true`, NixOS will:

        -   Add any libraries configured in NixOS and not configured on the
            Jellyfin server.
        -   Delete any libraries configured on the Jellyfin server and not
            configured in NixOS.
        -   Update any libraries configured in both NixOS and on the Jellyfin
            server such that the configuration on the Jellyfin server matches
            that configured in NixOS.

        If `false`, NixOS will:

        -   Add any libraries configured in NixOS and not configured on the
            Jellyfin server.
        -   Make no changes to any libraries already configured on the Jellyfin
            server.
      '';
      default = false;
    };
    libraryJsonFiles = mkOption {
      # TODO Check how to hide this, and how to set it as an appropriate
      # derivation
    };
    libraries = let
      libraryModule = {
        config,
        name,
        ...
      }: {
        options = {
          locations = mkOption {
            type = listOf path;
            description = "Paths to add to this library.";
            example = ["/home/user/music"];
          };
          type = mkOption {
            type = enum [
              "movies"
              "tvshows"
              "music"
              "musicvideos"
              "homevideos"
              "boxsets"
              "books"
              "mixed"
            ];
            description = "Centents of this library.";
          };
          metadataCountryCode = mkOption {
            description = "Metadata country code.";
            example = "US";
            default = cfg.localisation.metadataCountryCode;
            type = str;
          };
          preferredMetadataLanguage = mkOption {
            description = "Metadata language code.";
            example = "fr";
            default = cfg.localisation.preferredMetadataLanguage;
            type = str;
          };
          metadataSavers = mkOption {
            description = "Methods for saving the metadata.";
            example = [];
            default = ["Nfo"];
            type = listOf str;
          };
          seasonZeroDisplayName = mkOption {
            description = "Display name for season 0.";
            example = "Extras";
            default = "Specials";
            type = str;
          };
          fullConfig = mkOption {
            description = ''
              All configuration to be provided over the Library/VirtualFolder
              API endpoint to set up the library.
            '';
            #type = let
            #  # TODO Is there a better way to set this recursive definition?
            #  innerType = oneOf [bool str (attrsOf innerType) (listOf innerType)];
            #in
            #  attrsOf innerType;
            # TODO This all taken from one capture of adding a music library,
            # with a small number of modifications.  It's almost certainly not
            # appropriate for any other sort of library, and I need to fix
            # that.
            default = {
              inherit name;
              collectionType = config.type;
              refreshLibrary = true;
              LibraryOptions = {
                Enabled = true;
                EnableArchiveMediaFiles = false;
                EnablePhotos = true;
                EnableRealtimeMonitor = true;
                EnableLUFSScan = true;
                ExtractTrickplayImagesDuringLibraryScan = false;
                EnableTrickplayImageExtraction = false;
                ExtractChapterImagesDuringLibraryScan = false;
                EnableChapterImageExtraction = false;
                EnableInternetProviders = true;
                SaveLocalMetadata = true;
                EnableAutomaticSeriesGrouping = false;
                PreferredMetadataLanguage = config.preferredMetadataLanguage;
                MetadataCountryCode = config.metadataCountryCode;
                SeasonZeroDisplayName = config.seasonZeroDisplayName;
                AutomaticRefreshIntervalDays = 0;
                EnableEmbeddedTitles = false;
                EnableEmbeddedExtrasTitles = false;
                EnableEmbeddedEpisodeInfos = false;
                AllowEmbeddedSubtitles = "AllowAll";
                SkipSubtitlesIfEmbeddedSubtitlesPresent = false;
                SkipSubtitlesIfAudioTrackMatches = false;
                SaveSubtitlesWithMedia = true;
                SaveLyricsWithMedia = true;
                RequirePerfectSubtitleMatch = true;
                AutomaticallyAddToCollection = false;
                MetadataSavers = config.metadataSavers;
                TypeOptions = [
                  {
                    Type = "MusicArtist";
                    MetadataFetchers = [
                      "MusicBrainz"
                    ];
                    MetadataFetcherOrder = [
                      "TheAudioDB"
                      "MusicBrainz"
                    ];
                    ImageFetchers = [
                      "TheAudioDB"
                    ];
                    ImageFetcherOrder = [
                      "TheAudioDB"
                    ];
                  }
                  {
                    Type = "MusicAlbum";
                    MetadataFetchers = [
                      "MusicBrainz"
                    ];
                    MetadataFetcherOrder = [
                      "MusicBrainz"
                      "TheAudioDB"
                    ];
                    ImageFetchers = [
                      "TheAudioDB"
                    ];
                    ImageFetcherOrder = [
                      "TheAudioDB"
                    ];
                  }
                  {
                    Type = "Audio";
                    ImageFetchers = [
                      "Image Extractor"
                    ];
                    ImageFetcherOrder = [
                      "Image Extractor"
                    ];
                  }
                  {
                    Type = "MusicVideo";
                    ImageFetchers = [
                      "Embedded Image Extractor"
                      "Screen Grabber"
                    ];
                    ImageFetcherOrder = [
                      "Embedded Image Extractor"
                      "Screen Grabber"
                    ];
                  }
                ];
                LocalMetadataReaderOrder = config.metadataSavers;
                SubtitleDownloadLanguages = [];
                DisabledSubtitleFetchers = [];
                SubtitleFetcherOrder = [];
                PathInfos = map (p: {Path = p;}) config.locations;
              };
            };
          };
          jsonFile = mkOption {
            # TODO Check how to hide this, and how to set it as an appropriate
            # derivation.
          };
        };

        config.jsonFile = writeJsonFile name {
          url = {
            name = config.fullConfig.name;
            collectionType = config.fullConfig.collectionType;
            refreshLibrary = config.fullConfig.refreshLibrary;
          };
          body = builtins.removeAttrs config.fullConfig ["name" "collectionType" "refreshLibrary"];
        };
      };
    in
      mkOption {
        type = attrsOf (submodule libraryModule);
        description = "Libraries to configure.";
        example = {
          Music = {
            type = "music";
            paths = ["/home/user/music"];
          };
          Films = {
            type = "movies";
            paths = ["/usr/share/films"];
          };
        };
      };

    configTimeout = mkOption {
      description = ''
        Approximate number of seconds to keep attempting to perform initial
        setup and configuration.

        The Jellyfin service takes a while to be ready to respond to
        configuration requests.  This setting configures how long the
        configuration script should wait for Jellyfin; longer timeouts increase
        the chance of successfully configuring the server, but also delay
        noticing that the server is fatally misconfigured for some reason.

        Set to 0 to disable the timeout.
      '';
      type = ints.unsigned;
      default = 60;
    };

    forceReconfigure =
      mkEnableOption "deleting all Jellyfin config and starting again";
  };

  config = let
    configScript = let
      wizardConfigFile = writeJsonFile "wizard-config" {
        UICulture = cfg.localisation.ui;
        MetadataCountryCode = cfg.localisation.metadataCountryCode;
        PreferredMetadataLanguage =
          cfg.localisation.preferredMetadataLanguage;
      };

      # TODO Make this configurable
      remoteAccessConfigFile = writeJsonFile "remote-access-config" {
        EnableRemoteAccess = true;
        EnableAutomaticPortForwarding = false;
      };
    in
      pkgs.writeCheckedShellScript {
        name = "configure-jellyfin";
        purePath = true;
        text = let
          client = "configure-jellyfin";
          device =
            if opt.virtualHost.fqdn.isDefined
            then cfg.virtualHost.fqdn
            else config.networking.fqdn;
          version = "0";
        in
          ''
            set -x

            INTERNAL_PORT=${
              escapeShellArg (toString cfg.virtualHost.internalPort)
            }
            CONFIG_TIMEOUT=${escapeShellArg (toString cfg.configTimeout)}
            NETWORK_CONFIG_FILE=${escapeShellArg cfg.configDir}/network.xml
            DEVICE_ID="$(</etc/machine-id)"

            access_token=

            string_in_array () {
                local string="$1"
                local -n array_name="$2"
                local s
                for s in "''${array_name[@]}"; do
                    if [[ "$s" = "$string" ]]; then
                        return 0
                    fi
                done
                return 1
            }

            sleep () { ${pkgs.coreutils}/bin/sleep "$@"; }
            xmllint () { ${pkgs.libxml2}/bin/xmllint "$@"; }

            jq () {
                # Always want compact output.
                ${pkgs.jq}/bin/jq \
                    --compact-output \
                    "$@"
            }

            # Pre-parse and store login details.  In particular, we're reading
            # the password from a file, so it might have a trailing newline
            # that needs trimming.
            jq \
                --null-input \
                --arg initUser ${escapeShellArg cfg.users.initialUser.name} \
                --rawfile initPass \
                    ${escapeShellArg cfg.users.initialUser.passwordFile} \
                '{initUser: $initUser, initPass: $initPass | rtrimstr("\n")}' \
                > "$RUNTIME_DIRECTORY/inituser.json"

            printf -v plain_auth_header \
                'Authorization: MediaBrowser Client="%s", Device="%s", Version="%s", DeviceId="%s"' \
                ${escapeShellArgs [client device version]} \
                "$DEVICE_ID"

            if [[ -e "$NETWORK_CONFIG_FILE" ]]; then
                current_port="$(
                    xmllint \
                        --xpath \
                            'string(NetworkConfiguration/InternalHttpPort)' \
                        "$NETWORK_CONFIG_FILE"
                    )"
            else
                # If the network.xml file doesn't exist, that means the server
                # hasn't yet been configured, so the current port will be the
                # default.
                current_port=8096
            fi

            curljfapi () {
                local auth_header

                local endpoint="$1"
                shift

                if [[ "$access_token" ]]; then
                    printf -v auth_header \
                        '%s, Token="%s"' \
                        "$plain_auth_header" "$access_token"
                else
                    auth_header="$plain_auth_header"
                fi

                ${pkgs.curl}/bin/curl \
                    --silent \
                    --location \
                    --fail \
                    --header "$auth_header" \
                    "$@" \
                    127.0.0.1:"$current_port"/"$endpoint"
            }

            # Jellyfin can take a while to first respond, so just loop until
            # it's ready to respond and can provide its public info.
            declare -i config_attempts=0
            while :; do
                (( ++config_attempts ))

                if curljfapi System/Info/Public \
                    -o "$RUNTIME_DIRECTORY/publicinfo.json"
                then
                    # Jellyfin server ready
                    break
                else
                    rc="$?"
                fi

                if (( CONFIG_TIMEOUT == 0 )); then
                    printf -v attempt_msg '(attempt %d)' "$config_attempts"
                elif (( config_attempts > CONFIG_TIMEOUT )); then
                    echo 'Too many errors trying to connect to the Jellyfin server' >&2
                    exit 69 # EX_UNAVAILABLE
                else
                    printf -v attempt_msg \
                        '(attempt %d/%d)' \
                        "$config_attempts" \
                        "$CONFIG_TIMEOUT"
                fi

                if (( rc == 7 )); then
                    # Failed to connect to host.
                    printf 'Failed to connect to host %s\n' "$attempt_msg" >&2
                elif (( rc == 22 )); then
                    # HTTP page not retrieved.
                    printf 'Server error %s\n' "$attempt_msg" >&2
                fi

                sleep 1
            done

            startup_wizard_completed="$(
                jq --raw-output \
                    '
                      .StartupWizardCompleted
                      | if . == true
                        then "Yes"
                        elif . == false
                        then ""
                        else
                          "Unexpected value for .StartupWizardCompleted: \(.)"
                          | error
                        end
                  ' \
                  "$RUNTIME_DIRECTORY/publicinfo.json"
            )"

            if [[ -z "$startup_wizard_completed" ]]; then
                curljfapi Startup/Configuration --json @${wizardConfigFile}

                # Doing a GET of Startup/User seems pointless, but the
                # following POST doesn't work unless the GET has been completed
                # first.
                curljfapi Startup/User -o /dev/null
                jq '{Name: .initUser, Password: .initPass}' \
                        "$RUNTIME_DIRECTORY/inituser.json" \
                    | curljfapi Startup/User --json @-

                curljfapi Startup/RemoteAccess \
                    --json @${remoteAccessConfigFile}

                curljfapi Startup/Complete -X POST
            fi

            # TODO: allow authentication with API key rather than requiring a
            # username and password.
            jq '{Username: .initUser, Pw: .initPass}' \
                    "$RUNTIME_DIRECTORY/inituser.json" \
                | curljfapi Users/AuthenticateByName \
                    --json @- \
                    -o "$RUNTIME_DIRECTORY/auth.json"
            access_token="$(
                jq -r '.AccessToken' "$RUNTIME_DIRECTORY/auth.json"
            )"

            # Find out what libraries are already configured.
            curljfapi Library/VirtualFolders \
                -o "$RUNTIME_DIRECTORY/libraries.json"

            # shellcheck disable=SC2034 # Referenced indirectly
            declare -a current_library_names
            library_name_command="$(
                jq -r '
                    map(.Name | @sh)
                    | join(" ")
                    | "current_library_names=(\(.))"
                ' \
                "$RUNTIME_DIRECTORY/libraries.json"
            )"
            eval "$library_name_command"

          ''
          + lib.optionalString (!cfg.overrideLibraries) ''
            target_library_names=(${escapeShellArgs (builtins.attrNames cfg.libraries)})
            for name in "''${target_library_names[@]}"; do
                if ! string_in_array "$name" current_library_names; then
                    endpoint="Library/VirtualFolders?$(
                        jq -r '
                            .url
                            | to_entries
                            | map(
                                map_values(@uri)
                                | "\(.key)=\(.value)"
                              )
                            | join("&")
                        ' \
                        ${cfg.libraryJsonFiles}/"$name"
                    )"
                    jq '.body' ${cfg.libraryJsonFiles}/"$name" \
                        | curljfapi "$endpoint" --json @-
                fi
            done

          ''
          + lib.optionalString cfg.virtualHost.enable ''

            if [[ "$current_port" != "$INTERNAL_PORT" ]]; then
                # This relies on an undocumented API endpoint :(
                curljfapi System/Configuration/Network \
                    | jq --argjson internalPort "$INTERNAL_PORT" \
                        '.InternalHttpPort |= $internalPort' \
                    | curljfapi System/Configuration/Network \
                        --json @-

                # Need to restart to use the configured port number.
                curljfapi System/Restart -XPOST
            fi
          '';
      };

    virtualHostConfig = lib.mkIf cfg.virtualHost.enable {
      assertions = [
        {
          assertion = cfg.virtualHost.internalPort != 8096;
          message = ''
            You cannot use port 8096 as the internal port for connecting to the
            Jellyfin server, as that is the default port and would therefore
            allow access to the server before it has been secured by setting up
            the initial user configuration.
          '';
        }
      ];

      networking.firewall.allowedTCPPorts = [80];

      services.nginx = {
        enable = true;

        virtualHosts."${cfg.virtualHost.fqdn}".locations."/" = {
          proxyPass = "http://127.0.0.1:${toString cfg.virtualHost.internalPort}";
          recommendedProxySettings = true;
        };
      };
    };

    # Only add TLS settings if the user has configured at least one of the
    # options that indicates they want secure connections.
    virtualHostSecureConfig =
      lib.mkIf
      (
        (cfg.virtualHost.enableACME || cfg.virtualHost.forceSecureConnections)
        && cfg.virtualHost.enable
      )
      {
        networking.firewall.allowedTCPPorts = [443];

        services.nginx = {
          recommendedTlsSettings = true;
          virtualHosts."${cfg.virtualHost.fqdn}" = {
            enableACME = cfg.virtualHost.enableACME;
            forceSSL = cfg.virtualHost.forceSecureConnections;
          };
        };
      };

    # TODO Remove this configuration, as I'm only including it for testing
    # purposes.
    reconfigureConfig = {
      systemd.services.jellyfin-reconfigure = {
        description = "removing existing Jellyfin configuration";
        requiredBy = lib.mkIf cfg.forceReconfigure ["jellyfin.service"];
        before = ["jellyfin.service"];
        serviceConfig.Type = "oneshot";
        script = ''
          rm -rf ${
            lib.strings.escapeShellArgs
            [cfg.cacheDir cfg.dataDir cfg.configDir]
          }
          systemctl restart systemd-tmpfiles-resetup.service
        '';
      };
      systemd.services.jellyfin.restartTriggers =
        lib.mkIf cfg.forceReconfigure
        [
          config.systemd.units."jellyfin-configure.service".unit
          config.systemd.units."jellyfin-reconfigure.service".unit
        ];
    };

    commonConfig = {
      # TODO Remove this test code
      services.jellyfin.libraries.Music = {
        locations = ["/usr/local/share/av/music"];
        type = "music";
      };

      assertions = [
        # TODO Remove this limitation and this assertion.
        {
          assertion = !cfg.overrideLibraries;
          message = "services.jellyfin.overrideLibraries has not been implemented yet!";
        }
      ];

      services.jellyfin.libraryJsonFiles = pkgs.linkFarm "library-data" (
        lib.attrsets.mapAttrs
        (name: value: value.jsonFile)
        cfg.libraries
      );

      # Run the configure script with root permissions so it can access
      # password files.
      systemd.services.jellyfin-configure = {
        description = "Jellyfin configuration";
        serviceConfig = {
          Type = "oneshot";
          RuntimeDirectory = "%N";
          RuntimeDirectoryMode = "0700";

          # Various hardening options.  Probably not necessary, but does no
          # harm and may provide security benefits.
          PrivateDevices = true;
          PrivateIPC = true;
          PrivateTmp = true;
          ProtectClock = true;
          ProtectControlGroups = true;
          ProtectHostname = true;
          ProtectKernelLogs = true;
          ProtectKernelModules = true;
          ProtectKernelTunables = true;
          ProtectSystem = "strict";

          ExecStart = toString configScript;

          # Need remainAfterExit so nixos-rebuild knows it needs to restart
          # this unit if it changes.
          RemainAfterExit = true;
        };
        requiredBy = ["jellyfin.service"];
        bindsTo = ["jellyfin.service"];
        after = ["jellyfin.service"];
      };

      users.users."${config.users.me}".extraGroups = ["jellyfin"];
    };
  in
    lib.mkIf cfg.enable (
      lib.mkMerge [
        virtualHostConfig
        virtualHostSecureConfig
        reconfigureConfig
        commonConfig
      ]
    );
}
