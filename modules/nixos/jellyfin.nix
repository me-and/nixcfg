{
  config,
  lib,
  options,
  pkgs,
  utils,
  ...
}: let
  cfg = config.services.jellyfin;
  opt = options.services.jellyfin;

  inherit (builtins) attrValues toJSON toString;
  inherit (lib) mkIf mkMerge;
  inherit
    (lib.strings)
    concatLines
    concatStringsSep
    escapeShellArg
    escapeShellArgs
    optionalString
    ;
  inherit (lib.attrsets) mapAttrsToList;
  inherit (utils.systemdUtils.lib) unitNameType;

  writeJsonFile = filename: json:
    pkgs.writeText filename (toJSON json);

  escapeURL = v:
    if v == true
    then "true"
    else if v == false
    then "false"
    else lib.strings.escapeURL v;
  formatUrlParams = attrs:
    concatStringsSep "&"
    (
      mapAttrsToList
      (name: value: "${escapeURL name}=${escapeURL value}")
      attrs
    );
in {
  options.services.jellyfin = let
    inherit (lib) mkEnableOption mkOption;
    inherit
      (lib.types)
      anything
      attrsOf
      bool
      either
      enum
      ints
      listOf
      path
      str
      submodule
      ;

    libraryModule = {
      config,
      name,
      ...
    }: {
      options = {
        name = mkOption {
          description = "The name of the library.";
          type = str;
          default = name;
        };
        type = mkOption {
          description = "The type of the library.";
          example = "music";
          # TODO populate this list
          type = enum [
            "homevideos"
            "music"
            "movies"
            "tvshows"
          ];
        };
        paths = mkOption {
          type = listOf path;
          description = "Paths to add to this library.";
          example = ["/home/user/music"];
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
          description = "Methods for saving the metadata, in order.";
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
        skipSubtitlesIfAudioTrackMatches = mkOption {
          # I'd put a description here, but I've no idea what it does, only
          # that the default when omitted from the API doesn't match the
          # default when configured through the web GUI, and I want the config
          # to match what you'd get from the web GUI.
          type = bool;
          default = false;
        };
        subtitleDownloadLanguages = mkOption {
          description = "Languages to try to download subtitles in.";
          type = listOf str;
          default = [config.preferredMetadataLanguage];
        };
        includePhotos = mkOption {
          description = ''
            For home media libraries, whether to include photos alongside
            videos.
          '';
          type = bool;
          default = true;
        };
        realtimeMonitor = mkOption {
          description = ''
            Whether to enable realtime monitoring of the library filesystem for changes.
          '';
          type = bool;
          default = true;
        };
        lufsScan = mkOption {
          description = ''
            Whether to enable LUFS scanning for this library, which performs
            volume normalisation.
          '';
          type = bool;
          default = true;
        };
        saveLocalMetadata = mkOption {
          description = ''
            Whether to save metadata in the same directory as the media files.
          '';
          type = bool;
          default = true;
        };
        saveLyricsWithMedia = mkOption {
          description = ''
            Whether to save lyrics in the same directory as the media files.
          '';
          type = bool;
          default = true;
        };
        useEmbeddedTitles = mkOption {
          description = ''
            If metadata can't be found online, whether to prefer titles
            embedded in media files over titles based on the media file names.
          '';
          type = bool;
          default = true;
        };
        useEmbeddedEpisodeInfo = mkOption {
          description = ''
            Whether to prefer the episode information embedded in media files
            over information extracted from the media file names.
          '';
          type = bool;
          default = true;
        };
        automaticSeriesGrouping = mkOption {
          description = "Whether to automatically group series together.";
          type = bool;
          default = false;
        };
        automaticCollections = mkOption {
          description = "Whether to automatically group collections together.";
          type = bool;
          default = config.type == "movies";
        };
        fetchers = let
          fetcherModule = {
            config,
            name,
            ...
          }: {
            options = {
              type = mkOption {
                description = "Type of metadata.";
                default = name;
                type = str;
              };
              metadata = mkOption {
                description = "Fetchers to use to fetch metadata, in order.";
                type = listOf str;
              };
              images = mkOption {
                description = "Fetchers to use to fetch images, in order.";
                type = listOf str;
              };
              config = mkOption {
                description = ''
                  Full configuration that will be formatted as JSON to
                  configure this type.
                '';
                # TODO is there a better type for JSONable things?
                type = attrsOf anything;
              };
            };

            config = {
              config = {
                Type = config.type;
                MetadataFetchers = config.metadata;
                MetadataFetcherOrder = config.metadata;
                ImageFetchers = config.images;
                ImageFetcherOrder = config.images;
              };
            };
          };
        in
          mkOption {
            description = "Types of metadata to fetch, and how to fetch it.";
            type = attrsOf (submodule fetcherModule);
            default =
              if config.type == "music"
              then {
                MusicArtist = {
                  metadata = [
                    "MusicBrainz"
                    "TheAudioDB"
                  ];
                  images = ["TheAudioDB"];
                };
                MusicAlbum = {
                  metadata = [
                    "MusicBrainz"
                    "TheAudioDB"
                  ];
                  images = ["TheAudioDB"];
                };
                Audio = {
                  metadata = [];
                  images = ["Image Extractor"];
                };
                MusicVideo = {
                  metadata = [];
                  images = [
                    "Embedded Image Extractor"
                    "Screen Grabber"
                  ];
                };
              }
              else if config.type == "movies"
              then {
                Movie = {
                  metadata = [
                    "TheMovieDb"
                    "The Open Movie Database"
                  ];
                  images = [
                    "TheMovieDb"
                    "The Open Movie Database"
                    "Embedded Image Extractor"
                    "Screen Grabber"
                  ];
                };
              }
              else if config.type == "tvshows"
              then {
                Series = {
                  metadata = [
                    "TheMovieDb"
                    "The Open Movie Database"
                  ];
                  images = ["TheMovieDb"];
                };
                Season = {
                  metadata = ["TheMovieDb"];
                  images = ["TheMovieDb"];
                };
                Episode = {
                  metadata = [
                    "TheMovieDb"
                    "The Open Movie Database"
                  ];
                  images = [
                    "TheMovieDb"
                    "The Open Movie Database"
                    "Embedded Image Extractor"
                    "Screen Grabber"
                  ];
                };
              }
              else if config.type == "homevideos"
              then {
                Video = {
                  metadata = [];
                  images = [
                    "Embedded Image Extractor"
                    "Screen Grabber"
                  ];
                };
              }
              else {};
          };
        extraConfig = mkOption {
          description = ''
            Extra configuration to send on the Jellyfin Library/VirtualFolder
            REST API interface.
          '';
          # TODO is there a better type for JSONable things?
          type = attrsOf anything;
          default = {};
        };

        # TODO Hide these
        urlParameters = mkOption {
          description = ''
            URL parameters to pass on the request to create the library.
          '';
          type = attrsOf (either str bool);
        };
        config = mkOption {
          description = ''
            Full configuration that will be passed as the body of the request
            to create the library.
          '';
          # TODO is there a better type for JSONable things?
          type = attrsOf anything;
        };
        jsonConfigFile = mkOption {
          description = ''
            File containing the JSON-formatted data that will be passed as the request to create the library.
          '';
          # TODO What's an appropriate type?
        };
      };

      config = {
        urlParameters = {
          name = config.name;
          collectionType = config.type;
          refreshLibrary = true;
        };

        config = (
          {
            PathInfos = map (p: {Path = p;}) config.paths;
            MetadataCountryCode = config.metadataCountryCode;
            PreferredMetadataLanguage = config.preferredMetadataLanguage;
            MetadataSavers = config.metadataSavers;
            LocalMetadataReaderOrder = config.metadataSavers;
            SeasonZeroDisplayName = config.seasonZeroDisplayName;
            EnableRealtimeMonitor = config.realtimeMonitor;
            EnableLUFSScan = config.lufsScan;
            SaveLocalMetadata = config.saveLocalMetadata;
            EnableAutomaticSeriesGrouping = config.automaticSeriesGrouping;
            SkipSubtitlesIfAudioTrackMatches = config.skipSubtitlesIfAudioTrackMatches;
            SubtitleDownloadLanguages = config.subtitleDownloadLanguages;
            SaveLyricsWithMedia = config.saveLyricsWithMedia;
            TypeOptions = map (x: x.config) (attrValues config.fetchers);
            EnableEmbeddedTitles = config.useEmbeddedTitles;
            AutomaticallyAddToCollection = config.automaticCollections;
            EnableEmbeddedEpisodeInfos = config.useEmbeddedEpisodeInfo;
            EnablePhotos = config.includePhotos;
          }
          // config.extraConfig
        );

        jsonConfigFile = writeJsonFile name {
          LibraryOptions = config.config;
        };
      };
    };
  in {
    apiDebugScript = mkEnableOption "a script for making requests to the API";

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

    requiredSystemdUnits = mkOption {
      description = ''
        Systemd units that are required for Jellyfin to work.  This will
        typically be mount point units.  The Jellyfin systemd service will
        have "BindsTo" and "After" dependencies on units given here.
      '';
      type = listOf unitNameType;
      default = [];
      example = ["usr-local-share-music.mount"];
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

    libraries = mkOption {
      description = ''
        The libraries to configure on the Jellyfin server.
      '';
      type = attrsOf (submodule libraryModule);
      default = {};
      example = {
        Music = {
          type = "music";
          paths = ["/home/user/music"];
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
            sleep () { ${pkgs.coreutils}/bin/sleep "$@"; }
            xmllint () { ${pkgs.libxml2}/bin/xmllint "$@"; }
            jq () {
                # Always want compact output.
                ${pkgs.jq}/bin/jq \
                    --compact-output \
                    "$@"
            }
            curl () { ${pkgs.curl}/bin/curl "$@"; }

            INTERNAL_PORT=${toString cfg.virtualHost.internalPort}
            CONFIG_TIMEOUT=${toString cfg.configTimeout}
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

                curl \
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
          + optionalString (!cfg.overrideLibraries) (concatLines (
            map (
              library: ''
                if ! string_in_array \
                    ${escapeShellArg library.name} \
                    current_library_names
                then
                    curljfapi \
                        ${escapeShellArg ("Library/VirtualFolders?" + (formatUrlParams library.urlParameters))} \
                        --json @${library.jsonConfigFile}
                fi
              ''
            )
            (attrValues cfg.libraries)
          ))
          + optionalString cfg.virtualHost.enable ''

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

    virtualHostConfig = mkIf cfg.virtualHost.enable {
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

      systemd.services.jellyfin.wants = ["nginx.service"];
    };

    # Only add TLS settings if the user has configured at least one of the
    # options that indicates they want secure connections.
    virtualHostSecureConfig =
      mkIf
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
        requiredBy = mkIf cfg.forceReconfigure ["jellyfin.service"];
        before = ["jellyfin.service"];
        serviceConfig.Type = "oneshot";
        script = ''
          rm -rf ${escapeShellArgs [cfg.cacheDir cfg.dataDir cfg.configDir]}
          systemctl restart systemd-tmpfiles-resetup.service
        '';
      };
      systemd.services.jellyfin.restartTriggers =
        mkIf cfg.forceReconfigure
        [
          config.systemd.units."jellyfin-configure.service".unit
          config.systemd.units."jellyfin-reconfigure.service".unit
        ];
    };

    apiDebugConfig = let
      debugScript = pkgs.writeCheckedShellApplication {
        name = "jellyfin-api";
        purePath = true;
        runtimeInputs = [
          pkgs.libxml2
          pkgs.jq
          pkgs.coreutils
          pkgs.curl
        ];
        text = ''
          NETWORK_CONFIG_FILE=${escapeShellArg cfg.configDir}/network.xml
          DEVICE_ID="$(</etc/machine-id)"

          access_token=

          tmpdir="$(mktemp -dt "jellyfin-api.''$$.XXXXX")"
          trap 'rm -rf -- "$tmpdir"' EXIT

          # Pre-parse and store login details.  In particular, we're reading
          # the password from a file, so it might have a trailing newline that
          # needs trimming.
          jq \
              --null-input \
              --arg initUser ${escapeShellArg cfg.users.initialUser.name} \
              --rawfile initPass \
                  ${escapeShellArg cfg.users.initialUser.passwordFile} \
              '{Username: $initUser, Pw: $initPass | rtrimstr("\n")}' \
              > "$tmpdir/login.json"

          printf -v plain_auth_header \
              'Authorization: MediaBrowser Client="jellyfin-api-script", Device="jellyfin-api-script", Version="0", DeviceId="%s"' \
              "$DEVICE_ID"

          if [[ -e "$NETWORK_CONFIG_FILE" ]]; then
              current_port="$(
                  xmllint \
                      --xpath \
                          'string(NetworkConfiguration/InternalHttpPort)' \
                      "$NETWORK_CONFIG_FILE"
                  )"
          else
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

              curl \
                  --no-progress-meter \
                  --location \
                  --fail-with-body \
                  --header "$auth_header" \
                  "$@" \
                  127.0.0.1:"$current_port"/"$endpoint"
          }

          curljfapi Users/AuthenticateByName \
              --json @"$tmpdir"/login.json \
              -o "$tmpdir"/auth.json
          access_token="$(
              jq -r '.AccessToken' "$tmpdir"/auth.json
          )"

          curljfapi "$@"
        '';
      };
    in
      mkIf cfg.apiDebugScript {
        environment.systemPackages = [debugScript];
      };

    commonConfig = {
      assertions = [
        # TODO Remove this limitation and this assertion.
        {
          assertion = !cfg.overrideLibraries;
          message = "services.jellyfin.overrideLibraries has not been implemented yet!";
        }
      ];

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
        wantedBy = ["jellyfin.service"];
        bindsTo = ["jellyfin.service"];
        after = ["jellyfin.service"];
      };

      systemd.services.jellyfin = {
        bindsTo = cfg.requiredSystemdUnits;
        after = cfg.requiredSystemdUnits;
      };

      users.users."${config.users.me}".extraGroups = ["jellyfin"];
    };
  in
    mkIf cfg.enable (
      mkMerge [
        virtualHostConfig
        virtualHostSecureConfig
        reconfigureConfig
        commonConfig
        apiDebugConfig
      ]
    );
}
