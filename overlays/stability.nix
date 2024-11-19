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
  channelInfo = excludeOverlays:
    map (data: rec {
      name = data.metric.channel;
      status =
        if builtins.elem data.metric.status ["stable" "beta" "rolling" "unmaintained"]
        then data.metric.status
        else throw "Unexpected channel status ${data.metric.status} for channel ${name}";
      variant = let
        v = data.metric.variant or null;
      in
        if builtins.elem v ["primary" "small" "darwin" null]
        then v
        else throw "Unexpected channel variant ${v} for channel ${name}";
      url = "https://channels.nixos.org/${name}/nixexprs.tar.xz";
      pkgs =
        if excludeOverlays == null
        then import (builtins.fetchTarball url) {}
        else let
          # Based on the nixpkgs overlays configuration.
          path = ./.;
          content = builtins.readDir path;
          overlayFiles = builtins.filter (n:
            !(builtins.elem n excludeOverlays)
            && (
              (
                (builtins.match ".*\\.nix" n != null)
                && (builtins.match "\\.#.*" n == null)
              )
              || builtins.pathExists (path + ("/" + n + "/default.nix"))
            ))
          (builtins.attrNames content);
          overlays = map (n: import (path + ("/" + n))) overlayFiles;
        in
          import (builtins.fetchTarball url) {inherit overlays;};
    })
    channelData;

  allowedChannels = excludeOverlays:
    builtins.filter
    (c: c.status != "unmaintained" && c.variant != "darwin")
    (channelInfo excludeOverlays);

  # More stable = lower = at the front of the sorted list.
  #
  # Order by:
  # - status:
  #   - stable
  #   - beta
  #   - rolling
  # - variant:
  #   - primary
  #   - small
  #   - neither (which seems to mean "nixpkgs-unstable")
  #
  # Order tests assume the values are restricted by the filtering in
  # allowedChannels and the value tests in channelInfo.  The final `throw`
  # should only be hit in the event there are multiple channels that compare
  # identically, and shouldn't be hit if there are invalid/unexpected values.
  stabilityCmp = a: b:
    if a.status != b.status
    then
      if a.status == "stable"
      then true
      else if b.status == "stable"
      then false
      else a.status == "beta"
    else if a.variant != b.variant
    then
      if a.variant == "primary"
      then true
      else if b.variant == "primary"
      then false
      else a.variant == "small"
    else throw "Cannot sort channels ${a.name} and ${b.name} in stability order";

  channelsByStability = excludeOverlays:
    builtins.sort stabilityCmp (allowedChannels excludeOverlays);

  packageFromChannel = name: channel:
    final.lib.attrByPath (final.lib.splitString "." name) null channel.pkgs;
  packagesByStability = excludeOverlays: name:
    builtins.filter (p: p != null)
    (map (packageFromChannel name) (channelsByStability excludeOverlays));
in {
  lib = prev.lib.attrsets.recursiveUpdate prev.lib {
    channels = {
      mostStablePackageWith = {
        name,
        pred,
        default,
        excludeOverlays ? null,
        # If calling from an overlay, can add prev.package in case the local
        # package already satisfies the predicate.
        testFirst ? [],
      }:
        final.lib.findFirst pred default
        (testFirst ++ packagesByStability excludeOverlays name);

      mostStablePackage = {
        name,
        excludeOverlays ? null,
      }:
        final.lib.channels.mostStablePackageWith {
          inherit name excludeOverlays;
          pred = final.lib.trivial.const true;
          default = throw "No ${name} package available.";
        };

      mostStablePackageVersionAtLeast = {
        name,
        version,
        excludeOverlays ? null,
        testFirst ? [],
      }:
        final.lib.channels.mostStablePackageWith {
          inherit name excludeOverlays testFirst;
          pred = p: final.lib.versionAtLeast p.version version;
          default =
            throw "No ${name} package with version at least ${version} available";
        };
    };
  };
}
