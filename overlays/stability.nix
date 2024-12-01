final: prev: let
  # Strings are defined as variables just so accidental typos show up as errors
  # rather than silent string matching failures.
  stable = "stable";
  beta = "beta";
  rolling = "rolling";
  unmaintained = "unmaintained";
  primary = "primary";
  small = "small";
  darwin = "darwin";

  # Get information about the channels that are currently supported and
  # maintained.
  rawChannelData = builtins.fromJSON (
    builtins.readFile (
      builtins.fetchurl
      "https://prometheus.nixos.org/api/v1/query?query=channel_revision"
    )
  );
  channelData = rawChannelData.data.result;
  channelInfo = excludeOverlays: config: let
    # <nixpkgs/pkgs/top-level/impure.nix>
    homeDir = builtins.getEnv "HOME";
    configFile = builtins.getEnv "NIXPKGS_CONFIG";
    configFile2 = homeDir + "/.config/nixpkgs/config.nix";
    configFile3 = homeDir + "/.nixpkgs/config.nix";
    config' =
      if config == null
      then
        if configFile != "" && builtins.pathExists configFile
        then import configFile
        else if homeDir != "" && builtins.pathExists configFile2
        then import configFile2
        else if homeDir != "" && builtins.pathExists configFile3
        then import configFile3
        else {}
      else config;
  in
    map (data: rec {
      name = data.metric.channel;
      status =
        if builtins.elem data.metric.status [stable beta rolling unmaintained]
        then data.metric.status
        else throw "Unexpected channel status ${data.metric.status} for channel ${name}";
      variant = let
        v = data.metric.variant or null;
      in
        if builtins.elem v [primary small darwin null]
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
          import (builtins.fetchTarball url) {
            inherit overlays;
            config = config';
          };
    })
    channelData;

  allowedChannels = excludeOverlays: config:
    builtins.filter
    (c: c.status != unmaintained && c.variant != darwin)
    (channelInfo excludeOverlays config);

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
      if a.status == stable
      then true
      else if b.status == stable
      then false
      else a.status == beta
    else if a.variant != b.variant
    then
      if a.variant == primary
      then true
      else if b.variant == primary
      then false
      else a.variant == small
    else throw "Cannot sort channels ${a.name} and ${b.name} in stability order";

  channelsByStability = excludeOverlays: config:
    builtins.sort stabilityCmp (allowedChannels excludeOverlays config);

  packageFromChannel = name: channel:
    final.lib.attrByPath (final.lib.splitString "." name) null channel.pkgs;
  packagesByStability = excludeOverlays: config: name:
    map (packageFromChannel name) (channelsByStability excludeOverlays config);
in {
  lib = prev.lib.attrsets.recursiveUpdate prev.lib {
    channels = {
      mostStablePackageWith = {
        name,
        pred,
        default,
        excludeOverlays ? null,
        config ? null,
        # If calling from an overlay, can add prev.package in case the local
        # package already satisfies the predicate.
        testFirst ? [],
      }: let
        pred' = p: p != null && pred p;
      in
        final.lib.findFirst pred' default
        (testFirst ++ packagesByStability excludeOverlays config name);

      mostStablePackage = {
        name,
        excludeOverlays ? null,
        config ? null,
        default ? throw "No ${name} package available.",
      }:
        final.lib.channels.mostStablePackageWith {
          inherit name excludeOverlays config default;
          pred = final.lib.trivial.const true;
        };

      mostStablePackageVersionAtLeast = {
        name,
        version,
        excludeOverlays ? null,
        config ? null,
        testFirst ? [],
        default ? throw "No ${name} package with version at least ${version} available",
      }:
        final.lib.channels.mostStablePackageWith {
          inherit name excludeOverlays testFirst config default;
          pred = p: final.lib.versionAtLeast p.version version;
        };
    };
  };
}
