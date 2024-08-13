# Heavily based on
# https://dataswamp.org/~solene/2022-06-02-nixos-local-cache.html
{
  config,
  lib,
  ...
}: let
  cfg = config.services.nixBinaryCache;
in {
  options.services.nixBinaryCache = {
    enable = lib.mkEnableOption "local Nix binary cache server";

    serverName = lib.mkOption {
      description = "Name of the virtual host.";
      type = lib.types.str;
      default = "localhost";
      example = "mynixcache.example.org";
    };
    serverAliases = lib.mkOption {
      description = "Other server addresses on which to serve the cache";
      type = lib.types.listOf lib.types.str;
      default = ["127.0.0.1" "::1"];
      example = ["192.168.0.1" "mynixcache.example.org"];
    };

    upstream = lib.mkOption {
      description = "Upstream URL to fetch from.";
      type = lib.types.str;
      default = "http://cache.nixos.org";
    };

    # TODO Work out whether this can be made to work using the default system
    # DNS resolver.
    resolvers = lib.mkOption {
      description = "DNS servers";
      # Default to a selection of public DNS servers to rotate through.
      default = [
        "1.1.1.1"
        "1.0.0.1"
        "8.8.4.4"
        "8.8.8.8"
        "9.9.9.9"
        "149.112.112.112"
        "208.67.222.222"
        "208.67.220.220"
      ];
      type = lib.types.listOf lib.types.str;
    };

    useLocally = lib.mkOption {
      description = ''
        Whether to use the binary cache for the local system, as well as
        serving it for other systems.
      '';
      type = lib.types.bool;
      default = true;
    };

    cache.sizeLimit = lib.mkOption {
      description = ''
        Amount of disk space the cache is allowed to use before Nginx evicts
        old values.  Set to `null` to remove the maximum size limit.
      '';
      type = lib.types.nullOr lib.types.str;
      default = "20g";
    };
    cache.minFree = lib.mkOption {
      description = ''
        Minimum amount of disk space to leave on the disk storing the cache
        before Nginx evicts old values.  Set to `null` to remove the minimum
        free limit.
      '';
      type = lib.types.nullOr lib.types.str;
      default = "5g";
    };
    cache.ageLimit = lib.mkOption {
      description = "How long to cache files for.";
      type = lib.types.str;
      default = "365d";
    };
    cache.clearOnRestart = lib.mkOption {
      description = ''
        If `true`, the cache will be stored in a transient /tmp directory that
        is cleared every time the Nginx server is restarted.  If `false`, the
        cache will be stored in the persistent /var/cache directory, so the
        cache will persist over server restarts.
      '';
      type = lib.types.bool;
      default = false;
    };

    cache.zone.name = lib.mkOption {
      description = "Name to use for the Nginx cache zone.";
      type = lib.types.str;
      default = "nixbinarycache";
    };
    cache.zone.size = lib.mkOption {
      description = ''
        Amount of memory to use to store the cache information.  A one megabite
        zone can store around 8000 keys.
      '';
      type = lib.types.str;
      # Using as default the value from Solene's suggested configuration.
      default = "100m";
    };

    accessLogPath = lib.mkOption {
      description = ''
        Path to the file in which to store access logs.  If null, no access
        logs will be kept.
      '';
      type = lib.types.nullOr lib.types.path;
      default = null;
      example = "/var/log/nginx/access.log";
    };
  };

  config = let
    localCacheConfig = let
      inherit
        (cfg)
        accessLogPath
        cache
        enable
        resolvers
        serverAliases
        serverName
        upstream
        ;
      cacheDirectory =
        if cache.clearOnRestart
        then "/tmp/nginxcache"
        else "/var/cache/nginx";
    in
      lib.mkIf enable {
        services.nginx = {
          enable = true;

          appendHttpConfig = let
            proxyCachePathParams =
              [
                cacheDirectory
                "levels=2"
                "keys_zone=${cache.zone.name}:${cache.zone.size}"
                "inactive=${cache.ageLimit}"
                "use_temp_path=off"
              ]
              ++ (
                lib.optional (cache.sizeLimit != null)
                "max_size=${cache.sizeLimit}"
              )
              ++ (
                lib.optional (cache.minFree != null)
                "min_free=${cache.minFree}"
              );
          in ''
            proxy_cache_path ${lib.strings.concatStringsSep " " proxyCachePathParams};

            # Cache only success status codes; in particular we don't want to cache 404s.
            # See https://serverfault.com/a/690258/128321
            map $status $nix_binary_cache_header {
              200     "public";
              302     "public";
              default "no-cache";
            }
          '';

          virtualHosts."${serverName}" = {
            inherit serverAliases;
            locations."/" = {
              proxyPass = "$upstream_endpoint";
              extraConfig = ''
                proxy_cache ${cache.zone.name};
                proxy_cache_valid 200 302 60d;
                expires max;
                add_header Cache-Control $nix_binary_cache_header always;
              '';
            };

            # Using an Nginx variable for the upstream endpoint ensures that it
            # is resolved at runtime as opposed to once when the config file is
            # loaded and then cached forever (we don't want that):
            # see https://tenzer.dk/nginx-with-dynamic-upstreams/
            # This fixes errors like
            #   nginx: [emerg] host not found in upstream "upstream.example.com"
            # when the upstream host is not reachable for a short time when
            # nginx is started.
            extraConfig = lib.strings.concatLines (
              ["set $upstream_endpoint ${upstream};"]
              ++ (
                lib.optional (cfg.resolvers != [])
                "resolver ${lib.concatStringsSep " " resolvers};"
              )
              ++ (
                lib.optional (accessLogPath != null)
                "access_log ${accessLogPath};"
              )
            );
          };
        };

        # Use the proxy locally, too.  Use mkForce to ensure the upstream server
        # is never used directly.
        nix.settings.substituters =
          lib.mkIf cfg.useLocally
          (lib.mkForce ["http://${serverName}"]);
      };

    remoteCacheConfig = lib.mkIf (builtins.pathExists ../../local-config/substituters) {
      nix.settings.substituters =
        lib.splitString "\n"
        (lib.fileContents ../../local-config/substituters);
    };
  in
    lib.mkMerge [
      localCacheConfig
      remoteCacheConfig
    ];
}
