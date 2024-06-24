{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (builtins) attrNames concatStringsSep mapAttrs readDir;
  systemChannelDirContents =
    readDir /nix/var/nix/profiles/per-user/root/channels;
  expectedContents =
    {"manifest.nix" = "symlink";}
    // (mapAttrs (k: v: "symlink") config.nix.channels);
in {
  options = {
    nix.checkChannels = lib.mkEnableOption "channel list checking";
    nix.channels = lib.mkOption {
      default = {};
      type = lib.types.attrsOf lib.types.str;
      example = {
        nixos = "https://nixos.org/channels/nixos-23.11";
        home-manager = "https://github.com/nix-community/home-manager/archive/release-23.11.tar.gz";
      };
      description = "The channels to ensure are configured.";
    };
  };

  config = lib.mkIf config.nix.checkChannels {
    # At build time, check the list of channels that have been installed and
    # updated matches.  We can't reliably check whether the list has the
    # correct URLs, since we can't be sure we have access to
    # /root/.nix-channels.
    warnings = lib.optional (systemChannelDirContents != expectedContents) (
      ''
        The configured list of channel names doesn't match the expected list:
      ''
      + concatStringsSep "\n" (attrNames config.nix.channels)
    );

    # At activation time, however, we can check that the configured URLs are as
    # expected, too.
    system.activationScripts = {
      checkNixChannels = let
        channelListLines =
          lib.mapAttrsToList (k: v: "${v} ${k}") config.nix.channels;
        channelListFile =
          pkgs.writeText "expected-channel-list"
          (lib.concatLines channelListLines);
      in ''
        ${pkgs.diffutils}/bin/diff \
            <(sort ${channelListFile}) \
            <(sort ~root/.nix-channels)
      '';
    };
  };
}
