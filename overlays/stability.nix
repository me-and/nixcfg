final: prev: let
  # Get information about the channels that are currently supported and
  # maintained.
  rawChannelData = builtins.fromJSON (
    builtins.readFile (
      builtins.fetchurl
      "https://prometheus.nixos.org/api/v1/query?query=channel_revision"
    )
  );
  channelData = rawChannelData.data.result;
  channelInfo =
    map (data: rec {
      name = data.metric.channel;
      status =
        if builtins.elem data.metric.status ["stable" "rolling" "unmaintained"]
        then data.metric.status
        else throw "Unexpected channel status ${data.metric.status} for channel ${name}";
      variant = let
        v = data.metric.variant or null;
      in
        if builtins.elem v ["primary" "small" "darwin" null]
        then v
        else throw "Unexpected channel variant ${v} for channel ${name}";
      url = "https://channels.nixos.org/${name}/nixexprs.tar.xz";
      pkgs = import (builtins.fetchTarball url) {};
    })
    channelData;

  allowedChannels = builtins.filter (c: c.status != "unmaintained" && c.variant != "darwin") channelInfo;

  # More stable = lower = at the front of the sorted list.  Assume anything
  # marked as "stable" is more stable than anything that isn't, anything marked
  # as "small" is less stable than anything marked as "primary", and anything
  # with neither "small" nor "primary" labels -- which seems to mean
  # nixpkgs-unstable -- is least stable.
  #
  # Order tests assume the values are restricted by the filtering in
  # allowedChannels and the value tests in channelInfo.  The final `throw`
  # should only be hit in the event there are multiple channels that compare
  # identically.
  stabilityCmp = a: b:
    if a.status != b.status
    then a.status == "stable"
    else if a.variant != b.variant
    then
      if a.variant == "primary"
      then true
      else if b.variant == "primary"
      then false
      else a.variant == "small"
    else throw "Cannot sort channels ${a.name} and ${b.name} in stability order";

  channelsByStability = builtins.sort stabilityCmp allowedChannels;

  packageFromChannel = name: channel: final.lib.attrByPath (final.lib.splitString "." name) null channel.pkgs;
  packagesByStability = name: builtins.filter (p: p != null) (map (packageFromChannel name) channelsByStability);
in {
  lib = prev.lib.attrsets.recursiveUpdate prev.lib {
    channels = {
      mostStablePackageWith = {
        name,
        pred,
        default,
        testFirst ? [], # e.g. if calling from an overlay, add prev.package in case the local nixpkgs already satisfies the predicate
      }:
        final.lib.findFirst pred default (testFirst ++ packagesByStability name);

      mostStablePackageVersionAtLeast = {
        name,
        version,
        testFirst ? [],
      }:
        final.lib.channels.mostStablePackageWith {
          inherit name testFirst;
          pred = p: final.lib.versionAtLeast p.version version;
          default = throw "No ${name} package with version at least ${version} available";
        };
    };
  };
}
