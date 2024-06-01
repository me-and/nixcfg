{ config, lib, pkgs, ... }:
{
  options = {
    nix.checkChannels = lib.mkEnableOption "Enable channel list checking";
    nix.channels = lib.mkOption {
      default = {};
      type = lib.types.attrsOf lib.types.str;
      example = {
        nixos = "https://nixos.org/channels/nixos-23.11";
        home-manager =
          "https://github.com/nix-community/home-manager/archive/release-23.11.tar.gz";
      };
      description = lib.mdDoc ''
        The channels to ensure are configured.
      '';
    };
  };

  config.system.activationScripts = lib.mkIf config.nix.checkChannels {
    checkNixChannels =
      let
        channelListLines =
          lib.mapAttrsToList (k: v: "${v} ${k}") config.nix.channels;
        channelListFile = pkgs.writeText
          "expected-channel-list"
          (lib.concatLines channelListLines);
      in
      ''
      ${pkgs.diffutils}/bin/diff \
          <(sort ${channelListFile}) \
          <(sort ~root/.nix-channels)
      '';
  };
}
