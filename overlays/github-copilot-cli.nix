final: prev:
let
  inherit (final)
    lib
    fetchurl
    cacert
    nodejs
    bash
    ;
  version = "1.0.32";
in
{
  github-copilot-cli = prev.github-copilot-cli.overrideAttrs (
    finalAttrs: prevAttrs:
    lib.warnIf (lib.versionAtLeast prevAttrs.version version)
      "possibly unnecessary github-copilot-cli overlay"
      {
        inherit version;
        src = fetchurl {
          url = "https://github.com/github/copilot-cli/releases/download/v${finalAttrs.version}/github-copilot-${finalAttrs.version}.tgz";
          hash = "sha256-cB1JtronwFZc1d/B5zHeJbX0GmdvxvAEwT+pplUA1Do=";
        };
        sourceRoot = "package";
        autoPatchelfIgnoreMissingDeps = true;

        installPhase = ''
          runHook preInstall
          mkdir -p "$out"/lib/github-copilot-cli
          cp -r * "$out"/lib/github-copilot-cli
          runHook postInstall
        '';

        postInstall = ''
          makeWrapper ${nodejs}/bin/node "$out"/bin/copilot \
            --add-flag "$out"/lib/github-copilot-cli/index.js \
            --add-flag --no-auto-update \
            --set-default NODE_NO_WARNINGS 1 \
            --set-default SSL_CERT_DIR ${cacert}/etc/ssl/certs \
            --prefix PATH : ${lib.makeBinPath [ bash ]}
        '';
      }
  );
}
