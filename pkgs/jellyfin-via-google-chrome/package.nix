# Heavily based on Nixpkgs' netflix / netflix-via-google-chrome package.
# Notably provides much better handling of Chromecast devices than anything
# else I've been able to find for Jellyfin.
{
  fetchurl,
  google-chrome,
  lib,
  makeDesktopItem,
  runtimeShell,
  symlinkJoin,
  writeScriptBin,
  # command line arguments which are always set e.g "--disable-gpu"
  commandLineArgs ? [],
  # URL of the Jellyfin server.
  jellfinServerUrl ? "https://jelly.dinwoodie.org",
}: let
  name = "jellyfin-via-google-chrome";

  meta = {
    description = "Open Jellyfin in Google Chrome app mode";
    longDescription = ''
      This package installs an application launcher item that opens a specified
      Jellyfin server in a dedicated Google Chrome window. This package
      provides a quick and easy way to launch Jellyfin on a browser that
      supports Chromecast devices without polluting your application list with
      an otherwise-unused single-purpose browser.
    '';
    homepage = jellfinServerUrl;
    platforms = google-chrome.meta.platforms or lib.platforms.all;
  };

  desktopItem = makeDesktopItem {
    inherit name;
    # Executing by name as opposed to store path is conventional and prevents
    # copies of the desktop file from bitrotting too much.
    # (e.g. a copy in ~/.config/autostart, you lazy lazy bastard ;) )
    exec = name;
    icon = fetchurl {
      name = "jellyfin.svg";
      url = "https://github.com/jellyfin/jellyfin-ux/raw/refs/heads/master/branding/SVG/icon-transparent.svg";
      hash = "sha256-gXwltHRCsZIlBEj+SM1fJl/pGDvHWqEgMLvjNUlSVdE=";
    };
    desktopName = "Jellyfin via Google Chrome";
    genericName = "Jellyfin client with Chromecast support";
    categories = ["TV" "AudioVideo" "Network"];
    startupNotify = true;
  };

  script = writeScriptBin name ''
    #!${runtimeShell}
    exec ${google-chrome}/bin/${google-chrome.meta.mainProgram} ${lib.escapeShellArgs commandLineArgs} \
      --app=${lib.escapeShellArg jellfinServerUrl} \
      --no-first-run \
      --no-default-browser-check \
      --no-crash-upload \
      "$@"
  '';
in
  symlinkJoin {
    inherit name meta;
    paths = [script desktopItem];
  }
