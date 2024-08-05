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
    inherit (lib.types) bool ints path str;
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
    };

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
          used for setting all other Jellyfin configuration, so it will need
          to be an administrator account.
        '';
        example = "jellyfin";
        type = str;
      };
      passwordFile = mkOption {
        description = ''
          Path to a file containing the initial user's password.

          This needs to be kept up-to-date: it will be set during initial
          configuration, and (assuming you are not rebuilding the Jellyfin
          configuration from scratch every time) will be used on subsequent
          configuration phases to update the Jellyfin configuration.
        '';
        example = /etc/nixos/secrets/jellyfin-user-pw;
        type = path;
        apply = toString;
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
      default = 30;
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
        in ''
          set -x

          CONFIG_TIMEOUT=${escapeShellArg (toString cfg.configTimeout)}
          DEVICE_ID="$(</etc/machine-id)"

          access_token=

          sleep () { ${pkgs.coreutils}/bin/sleep "$@"; }

          jq () {
              # Always want compact output.
              ${pkgs.jq}/bin/jq \
                  --compact-output \
                  "$@"
          }

          # Pre-parse and store login details.  In particular, we're reading
          # the password from a file, so it might have a trailing newline that
          # needs trimming.
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
                  127.0.0.1:8096/"$endpoint"
          }

          # Jellyfin can take a while to first respond, so just loop until it's
          # ready to respond and can provide its public info.
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
              else
                  # Not an expected error code for while we're waiting for
                  # Jellyfin to be available, so bail out immediately.
                  printf 'curl error code %d %s\n' "$rc" "$attempt_msg" >&2
                  exit 76 # EX_PROTOCOL
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

              # Doing a GET of Startup/User seems pointless, but the following
              # POST doesn't work unless the GET has been completed first.
              curljfapi Startup/User -o /dev/null
              jq '{Name: .initUser, Password: .initPass}' \
                      "$RUNTIME_DIRECTORY/inituser.json" \
                  | curljfapi Startup/User --json @-

              curljfapi Startup/RemoteAccess --json @${remoteAccessConfigFile}

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

          # TODO Remove this line; it's only present to confirm the
          # authentication has succeeded in the absence of doing anything more
          # practical with the authentication token during the initial setup.
          curljfapi System/Configuration
        '';
      };

    virtualHostConfig = lib.mkIf cfg.virtualHost.enable {
      networking.firewall.allowedTCPPorts = [80];

      services.nginx = {
        # TODO Work out how to make sure the Nginx proxying is only available
        # after the initial configuration has completed, and therefore there's
        # no timing window where an attacker might be able to log in from
        # elsewhere to set the initial user config before the configuration
        # script has done so.
        enable = true;

        virtualHosts."${cfg.virtualHost.fqdn}".locations."/" = {
          proxyPass = "http://127.0.0.1:8096";
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
    reconfigureConfig = lib.mkIf cfg.forceReconfigure {
      systemd.services.jellyfin-reconfigure = {
        description = "removing existing Jellyfin configuration";
        requiredBy = ["jellyfin.service"];
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
      systemd.services.jellyfin.restartTriggers = [
        config.systemd.units."jellyfin-reconfigure.service".unit
      ];
    };

    configureConfig = {
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
        };
        requiredBy = ["jellyfin.service"];
        bindsTo = ["jellyfin.service"];
        after = ["jellyfin.service"];
      };
      systemd.services.jellyfin.restartTriggers = [
        config.systemd.units."jellyfin-configure.service".unit
      ];
    };
  in
    lib.mkIf cfg.enable (
      lib.mkMerge [
        virtualHostConfig
        virtualHostSecureConfig
        reconfigureConfig
        configureConfig
      ]
    );
}
