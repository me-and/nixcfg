# github-copilot-cli, but with my changes applied per
# https://github.com/NixOS/nixpkgs/pull/511768
{
  lib,
  mylib,
  fetchurl,
  cacert,
  nodejs,
  bash,
  github-copilot-cli,
  nix-update-script,
}:
github-copilot-cli.overrideAttrs (
  finalAttrs: prevAttrs: {
    pname = "github-copilot-cli-universal";
    version = "1.0.49";

    src =
      lib.warnIf (lib.versionOlder finalAttrs.version prevAttrs.version)
        ''
          github-copilot-cli has a newer version than my
          github-copilot-cli-universal, so my package probably wants
          updating.
        ''
        fetchurl
        {
          url = "https://github.com/github/copilot-cli/releases/download/v${finalAttrs.version}/github-copilot-${finalAttrs.version}.tgz";
          hash = "sha256-DHqo7cGuGISKJ+7y8wZXmDQPt6mFzfum5enLALf8mNU=";
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

    passthru.updateScript = nix-update-script {
      attrPath = "github-copilot-cli-universal";
      extraArgs = [
        "--use-github-releases"
        "--flake"
      ];
    };

    # Permit builds of the package as part of `nix flake check`.
    meta = prevAttrs.meta // {
      license = mylib.licenses.licensedToMe;
    };
  }
)
