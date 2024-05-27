{ config, lib, pkgs, ... }:
{
  options = {
    nix.checkChannels = lib.mkEnableOption "Enable channel list checking";
    nix.channels = lib.mkOption {
      default = {};
      type = lib.types.attrsOf lib.types.str;
      example = {
        nixos = "https://nixos.org/channels/nixos-23.11";
        home-manager = "https://github.com/nix-community/home-manager/archive/release-23.11.tar.gz";
      };
    };
  };

  config.system.activationScripts = lib.mkIf config.nix.checkChannels {
    checkNixChannels =
      let channelListFile = pkgs.writeText "expected-channel-list" (lib.concatLines (lib.mapAttrsToList (k: v: "${v} ${k}") config.nix.channels));
      in "${pkgs.diffutils}/bin/diff <(sort ${channelListFile}) <(sort ~root/.nix-channels)";
  };
#    system.activationScripts.checkNixChannels = (pkgs.writeShellScript "check-nix-channels.sh" (''
#      set -euo pipefail
#
#      declare -A channels
#      while read -r channel url; do
#        channels["$channel"]="$url"
#      done < <(${pkgs.nix}/bin/nix-channel --list)
#
#      rc=0
#
#      check_channel () {
#        local channel="$1"
#        local url="$2"
#        if [[ -v channels["$channel"] ]]; then
#          if [[ "''${channels["$channel"]}" = "$url" ]]; then
#            unset channels["$channel"]
#          else
#            printf 'unexpected url for channel %s (saw %s, expected %s)\n' "$channel" "''${channels["$channel"]}" "$url"
#            rc=1
#          fi
#        else
#          printf 'missing channel %s (%s)\n' "$channel" "$url" >&2
#          rc=1
#        fi
#      }
#
#    ''
#    + lib.concatLines (lib.mapAttrsToList (k: v: "check_channel ${lib.escapeShellArg k} ${lib.escapeShellArg v}") config.nix.channels)
#    + ''
#
#      if (( "''${#channels[*]}" != 0 )); then
#        for key in "''${!channels[@]}"; do
#          printf 'unexpected channel %s (%s)\n' "$key" "''${channels["$key"]}" >&2
#          rc=1
#        done
#      fi
#
#      exit "$rc"
#    '')).outPath;
#  };
}
