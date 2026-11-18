{
  lib,
  fetchurl,
  appimageTools,
  stdenv,
  makeDesktopItem,
}:
appimageTools.wrapType2 (finalAttrs: {
  pname = "thaura";
  version = "1.1.29";

  src =
    {
      # Hashes are in sha512 format so they can be directly copied / verified
      # against the hashes at https://thaura.ai/download
      x86_64-linux = fetchurl {
        url = "https://thaura.ai/downloads/Thaura-${finalAttrs.version}-x86_64.AppImage";
        sha512 = "c0d184b9cf6de3617d56b28720bec9201b665dd8ccd50516f405e79fc1b7df61adaae88d5cb821923cecba567fda00fc06e2704b6d0c421172f6c8afa03fcdfd";
      };
      aarch64-linux = fetchurl {
        url = "https://thaura.ai/downloads/Thaura-${finalAttrs.version}-arm64.AppImage";
        sha512 = "ffc69868e19614456de6d9084a2591c2b8e8c9cfc3c3435150de87260287e2fbeed23561b2866fd50d8de525d2a9f9a065feccb61f1c6752d4c57f1c340197f1";
      };
    }
    .${stdenv.hostPlatform.system};

  extraInstallCommands =
    let
      desktopItem = makeDesktopItem {
        name = "thaura";
        desktopName = "Thaura";
        icon = fetchurl {
          url = "https://thaura.ai/downloads/thaura-icon.png";
          hash = "sha256-9DsZNt3vx+wUrCZqiClxyPa6bPGI31cs2cWbf8eAEsw=";
        };

        comment = "Privacy-first AI desktop app";
        exec = "thaura";
        type = "Application";
        categories = [
          "Office"
          "Science"
          "Education"
        ];
        startupWMClass = "Thaura";
        terminal = false;
      };
    in
    ''
      mkdir "$out"/share
      ln -s ${desktopItem}/share/applications "$out"/share
    '';

  # TODO write passthru.updateScript
  # https://thaura.ai/downloads/latest-linux.yml
  # https://thaura.ai/downloads/latest-linux-arm64.yml
  # passthru.updateScript = ...

  meta = {
    description = "Desktop AI client";
    homepage = "https://thaura.ai";
    downloadPage = "https://thaura.ai/download";
    license = lib.licenses.unfree;
    sourceProvenance = lib.sourceTypes.binaryNativeCode;
    maintainers = [ lib.maintainers.me-and ];
    mainProgram = "thaura";
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
    ];
  };
})
