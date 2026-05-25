{
  lib,
  pkgs,
  osConfig,
  ...
}:
let
  image = pkgs.mypkgs.copilot-container;
  fullImageRef = "${image.imageName}:${image.imageTag}";
  tokenFile = osConfig.sops.secrets.github-token.path;
  containerPath = lib.makeBinPath [
    pkgs.bash
    pkgs.coreutils
    pkgs.findutils
    pkgs.git
    pkgs.gnugrep
    pkgs.gnused
    pkgs.mypkgs.github-copilot-cli-universal
  ];
  copilotBin = "${pkgs.mypkgs.github-copilot-cli-universal}/bin/copilot";
  loadImageScript = pkgs.mypkgs.writeCheckedShellScript {
    name = "copilot-container-load";
    runtimeInputs = [ pkgs.podman ];
    text = ''
      "${image}" | podman load
    '';
  };
in
lib.mkIf osConfig.nix.githubTokenFromSops {
  home.activation.copilot-container-load = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD "${loadImageScript}"
  '';

  home.packages = [
    (pkgs.mypkgs.writeCheckedShellApplication {
      name = "copilot-container";
      runtimeInputs = [ pkgs.podman ];
      text = ''
        data_dir="$HOME/.local/share/copilot-container"
        mkdir -p "$data_dir"

        if ! podman image exists "${fullImageRef}"; then
            echo "Loading container image..." >&2
            "${loadImageScript}"
        fi

        tty_flags=(--interactive)
        if [[ -t 0 ]]; then
            tty_flags+=(--tty)
        fi

        github_token="$(< "${tokenFile}")"
        exec podman run \
            --rm \
            "''${tty_flags[@]}" \
            --userns=keep-id \
            --volume /nix/store:/nix/store:ro \
            --volume "$PWD:/work" \
            --volume "$data_dir:/home/user" \
            --workdir /work \
            --env "HOME=/home/user" \
            --env "PATH=${containerPath}" \
            --env "GITHUB_TOKEN=$github_token" \
            --security-opt no-new-privileges=true \
            --cap-drop ALL \
            "${fullImageRef}" \
            "${copilotBin}" "$@"
      '';
    })
  ];
}
